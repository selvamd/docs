## Enterprise Architecture

The following diagram describes proposed enterprise system architecture for QXO. 

- Diagram shows a set of systems & processes that are operational and others that are analytical in nature. 
This is not cut in stone as sometimes operational systems do need to do some domain specific analytics

- When operations spread across systems, it is unavoidable to have some functional dependencies on what is 
happening in other systems. This creates a need for robust and timely data sharing.  

- Logging of the transactions and activities happen in all operational systems to support this. 
The data in these logs are also the source for all the tracking and reporting created in analytic processes

- Master data: Consists of maintaining a list of known entities like customers, vendors, branches, products etc. 
This doesnot change frequently like transactions but nevertheless latest updates needs to be maintained and actively 
shared with all applications, operational and analytics alike, as all transactions are linked to them.  

- In Beacon, mincron was the do-it-all application with long tail of systems supporting the missing functionality. 
This nearly monolithic solution minimized the data exchange needs so a mature data sharing mechanism was never developed

- When we modernize, this will not work. The solutions we are looking at are more sophisticated and specialized, 
and whether we build or buy, will be more modular and will require a very mature Enterprise Application Integration (EAI) strategy 

- When we decide to buy a product instead of building, it is important to think about the customizability or openness of the solution. 
Vendors interest is in generalizing the problems and solving them to maximize their software sales. Our interest is in finding the edges that others donot have or see and deliver innovations to scale growth and create margin expansion. These are inherently at cross roads to each other. 

- However, the fineline we have to walk, is to not re-invent the wheel and take out of the box solutions where we can if it provides strategic accelerations but make sure we donot get locked in and retain the ability to override things when we want to customize. Otherwise today's innovation becomes tomorrow's technical debt. 


```mermaid
graph LR

  subgraph CORP[Internal Systems]
    FIN[Accounting<br>Finance]
    AR[Invoices<br>Receivables]
    HRMS[Human<br>Resources]
  end

  subgraph CUSTSYS[Customer Sales and Marketing]
    MKT[Marketing<br>Branch Sales]
    DIGI[Digial<br>eCommerce]
    CDP[Customer Data<br>Platform]
  end

  subgraph OPER[Operational Applications - ERP]
    INV[Inventory<br>Warehouse]
    FLEET[Transportation<br>Logistics]
    PROC[Product<br>Procurement<br>Pricing]
  end

  subgraph MDM[Master Data/EAI Layer]
    CUST[Companies<br>Contacts]
    VEND[Vendors<br>Products]
    LOC[Branches<br>Employees]
  end

  subgraph EXT[External Data]
    LEAD[New Leads<br>Prospects]
    WEAT[Weather<br>Events]
    OPPR[Permits<br>Approvals]
    COMP[Competition]
  end

  subgraph RPT[Enterprise Data Management]
    DataLake[Data Lake]
    DWH[Data Warehouse]
    BI[Analytics & Reporting]
    AIML[AI/ML Systems]
  end

  %% Data Flow
  OPER --> RPT
  CUSTSYS --> RPT
  CORP --> RPT
  EXT --> RPT

  OPER <--> MDM
  CUSTSYS <--> MDM
  CORP <--> MDM
  MDM <--> RPT

  DataLake --> DWH
  DWH --> BI
  DWH --> AIML
```    
-------------------------------------------------------------------------------------------------------
#### Lakehouse Internal Architecture
```mermaid
flowchart LR
subgraph FE[Data Sources]
    direction LR
    MIN[MINCRON DB2]
    ERP[Oracle Fusion ERP]
    SCM[O9 PriceFx SCM]
    MS[OMS TMS WMS POS]
    FIN[Financials]
    HR[Workday HCM]
    CDP[Customer Data Platform]
    CRM[Salesforce]
end

subgraph ORC[Orchestration Tools]
    COMP[Composer/Airflow]
    DBT[DBT]
end 

subgraph INT[Integration Layer]
    direction LR
    OIC[Oracle Integration Cloud]
    PROC[Dataproc]
    DLT[Data Loading Tool]
    EXT[FiveTran AirByte]
end

subgraph GCS[Landing Zone/GCS Buckets]
    subgraph RAW[Raw/Bronze]
        direction LR
        SEMI[SEMI-STRUCTURED JSON, XML]
        STRUCT[AVRO, PARQUET, CSV, ICEBERG]
        UNSTRUCT[Texts, HTML, Markdown]
        BINARY[Images, Audio, Video, PDFs]
    end
    ARCH[Cold Storage\nArchived Legacy Data]
end

subgraph BQ[Transform Zone/Bigquery]
    subgraph XFORM[Curated/Silver]
        direction LR
        Cleaned[Cleaned Data]
        Validated[Validated Data]
        Schema[Schema Conformance]
    end
    subgraph NRICH[Semantic Gold Layer]
        subgraph Core[Dimensions/Star Schema]
            cust[Customer]
            prod[Products]
            branch[Branch]
        end
        subgraph FactTables[Fact/Metrics Tables]
            sales[Sales Fact]
            price[Prices Fact]
            inventory[Inventory Fact]
        end
    end
    subgraph PRD[Data Products]
        direction LR
        mktstudy[Marketing ROI]
        salerev[Sales Enablement]
        branchperf[Branch Performance]
        empperf[Employee Reviews]
        rept[Revenue and Margin Reporting]
    end
end

subgraph Tools[Consumer Applications]
    direction LR
    subgraph BI[Reporting & Visualization]
        direction TB
        tableau
        looker
        cognos
        alteryx
    end
    subgraph APP[Applications]
        rpt[Python Plotly]
        Streamlit
        agent[Agentic<br>Applications] 
    end
    subgraph AI[Interactive Analysis]
        direction TB
        workbench[AI Workbench]
        jupyter[Jupyter Notebooks]
        collab[Collaborative Notebooks]
    end
    subgraph OTH[Others]
        direction TB
        extracts[API Extracts]
        down[Data Downloads]
    end
end

subgraph MLOps[Vertex AI MLOps]
    direction TB
    subgraph FEAT[Feature Store]
        direction LR
        featengg[Feature Engineering]
        featmon[Feature Drift Monitoring]
    end
    subgraph MDEV[Model Development]
        direction LR
        train[Model Training]
        tune[Model Tuning & Optimization]
        reg[Model Registry]
    end
    subgraph MDEP[Model Deployment]
        direction LR
        deploy[Model Deployment]
        monitor[Model Monitoring]
        predict[Model Inference]
    end
end

%% Connections
FE --> INT
COMP --> RAW
COMP --> ARCH
COMP --> XFORM
COMP --> DBT
INT --> |LOAD| RAW
RAW --> |MOVE| ARCH
RAW --> |CLEAN| XFORM
DBT --> NRICH
DBT --> PRD
XFORM --> |DBT| NRICH
NRICH --> |DBT| PRD
PRD --> Tools
NRICH --> Tools

%% MLOps Connections
NRICH --> |Features| FEAT
FEAT --> MDEV
MDEV --> MDEP
MDEP --> PRD
MDEP --> Tools
```    
-------------------------------------------------------------------------------------------------------
#### Warehouse design goals 
- Only focuses on what needs to be built on top of any platform we decide to use. 
- Business goals  
    - Provide data as single source of truth for various consumers across the organization 
    - Scale BI/AI functions - Analysis/Reporting for tracking, knowledge, insights and intelligence  
    - Create schema consistency and standardization for self-service BI capabilities
    - Stitch data from external/internal sources for augmenting operational (leads) 
        and analytic (forecasting) capabilities 
    - Consolidate data from multiple future business aquisitions for unified analysis, 
        reporting and consumption purposes
    - Decoupled and independent data integration process from operational integration during M&A 
    - Enable systematic historical analysis and cross sectional analysis for studying 
        growth and evolution

- Technical goals
    - Create a functional abstraction based data model and supporting API led ingestion process 
    - Support multiple forms of ingestion as well as consumption - Batch/Realtime and Snapshot/Incremental
    - Datamodel driven quality checks and governance in addition to TDQ, BDQ  
    - Implementing reliable entity management supported by static, universal, non-recycled keys 
    - Handling key splits and merges with historical and ongoing data consistency  
        - Use of surrogate warehouse keys to decouple from operational systems dependency 
    - Adopting proper change data capture (CDC) strategy to store continious history 
    - Ensuring a managed and controlled ecosystem with 
        - Action/state consistency 
        - Leave no change untracked 
            - Incremental Write-ahead with no overwrites
            - History on both data/schema evolution
            - No data without metadata policy 

- Stages of intelligence in a data warehouse: 
    - Gathering and organizing data on activities within the system
    - Summarize and provide overview on what is happening (Descriptive)
    - Define metrics, KPIs that define the state/condition of the business entities
    - Build benchmarks around it to distinguish between normal vs abnormal changes
    - Observe and analyze to answer what is happening (Diagnostic)
    - Define targets and manage reactively towards achieving that
    - Analyze correlation and causation of actions and outcomes (Predictive) 
    - Predict future events using the metrics on activities observed
    - Adust and course correct pro-actively based on predictions (Prescriptive)
    - In that sense
        - Datawarehouse teams, by collecting/recording data, are building sensors
        - Reporting teams, by analyzing data, are making the system sentient
        - AI teams, by adding reasoning and predicting ability, are making the system intelligent
    - Note that this is a step by step progression and progress in each step depends on successful execution of the previous step

- System Integration goals
    - One of our known strategies is to grow the business through integrations and aquisitions
    - Design for keeping **data/analytics integrations decoupled from operational integration** so both can happen in parallel. 
    - Huge boost our effectivess as it will accelerate the knowledge gathering exercise for the executive management team during M&A

- Having a Data model that not too Beacon centric but based on abstraction of business functions in more generalized terms
- Time travel support and capture of continious history (not just snapshots)
- Support for incremental and full feature recomputes
-------------------------------------------------------------------------------------------------------
#### Modern data warehouse - Platform features
- Cloud-Native and Scalable
    - Elastic Scalability: Automatically scales compute and storage independently, often with near-infinite capacity.
    - Pay-as-you-go: Charges based on usage—no need to provision hardware.

- Multi-cloud / Hybrid Support: 
    - Enables deployment across multiple cloud providers and on-premise environments.

- Separation of Compute and Storage
    - Decoupled Architecture: Allows scaling compute resources without moving or duplicating data.
    - Parallel Processing: Distributed engines can query vast amounts of data in seconds.

- Support for Semi-Structured and Unstructured Data
    - Flexible Data Ingestion: Supports JSON, Avro, Parquet, ORC, XML, etc.

- Unified Storage Layer 
    - Can process both structured (SQL) and semi/unstructured data from the same platform.

- Integrated Data Lake and Lakehouse Capabilities
    - Converged Architecture: Modern warehouses often integrate or coexist with data lakes, 
    - forming lakehouse solutions (e.g., Databricks, Snowflake).

- Open Formats: Support for Delta Lake, Iceberg, or Apache Hudi for managing large-scale, versioned data.

- Strong Security and Governance
    - End-to-End Encryption: Both at rest and in transit.

- Granular Access Control: 
    - Role-based access, row-level and column-level security.

- Data Lineage and Auditing: 
    - Tracks where data comes from, how it's transformed, and who accessed it.

- Real-Time and Streaming Capabilities
    - Low-Latency Ingestion: Can ingest and query streaming data (e.g., via Kafka, Pub/Sub).
    - Change Data Capture (CDC): Supports real-time updates via tools like Debezium or built-in CDC features.

- Built-In Machine Learning and Analytics
    - ML Integration: Connects seamlessly with ML frameworks or offers built-in ML (e.g., BigQuery ML, Redshift ML).
    - Advanced Analytics: Supports time-series, geospatial, and predictive analytics directly via SQL or APIs.

- Serverless or Managed Infrastructure
    - Fully Managed Services: Reduces operational overhead—no manual patching or tuning.
    - Auto Tuning: Optimizes performance automatically based on workload patterns.

- Robust Data Integration and ETL/ELT Tools
    - ETL/ELT Integration: Compatible with modern data pipeline tools (Fivetran, dbt, Airflow).
    - In-database Transformations: Enables ELT-style workflows directly within the data warehouse.

- Support for SQL and Beyond
    - SQL-first Interfaces: Core support for SQL, but also extensible to Python, R, or other languages.
    - BI Tool Compatibility: Integrates natively with Looker, Tableau, Power BI, etc.
---------------------------------------------------------------------------------------------------------
#### GCP Data platform - Databricks level feature Parity
- Google Cloud Storage
    - Data Lakehouse Storage for raw/curated data lake storage
- BigQuery
    - Interactive analytics and warehousing
    - Can push unaccessed history data seamlessly to low-cost storage
    - Streaming inserts for changing data while supporting concurrent queries
- BigTable
    - OLTP, persistent cache for concurrent latest data in analytics 
- Dataproc - Managed Spark/Big Data Compute Dataproc.
    - Fully managed Spark, Hadoop, and other open-source tools 
    - for batch and streaming workloads.
- Cloud Composer (Airflow)
    - Data Workflow orchestration for ETL pipelines.
    - DBT - SQL with CICD/Testing  
- Data Streaming
    - Pub/Sub - Real-time messaging (Pub/Sub)
- Dataflow - stream/batch processing.
    - Machine Learning Lifecycle
- Vertex AI 
    - Unified ML platform for training, deploying, and managing models.
- Collaborative Notebooks
    - Vertex AI Workbench or Colab Enterprise
    - Managed Jupyter notebooks for team collaboration and development.
- Data Integration/ETL
    - Cloud Data Fusion or Dataprep Visual ETL and data preparation pipelines.
- Data Governance & Catalog
    - Dataplex - Governance, cataloging, and policy enforcement for lakes and warehouses.
- BI & Visualization
    - Looker - Business intelligence, dashboards, and visualization
---------------------------------------------------------------------------------
#### Datawarehouse Project plan 
- Team and Staffing
    - Project Owner (Me)
    - Solutions Architect (Me)
    - Product Owner (Stephanie/Shawn)
    - Business SME (Stephanie/Shawn)
    - Data SME (Mike Gazi/Mary)
    - Line of credit model
        - Data Analysts
        - Data Engineers 
        - Quality Engineer
    - Skills (Contract to Hire Model)
        - Knowledge, Communication 
        - Commitment, Productivity 
- Cost estimates
    - Platform Costs
        - Initial Development
        - Perpetual Costs    
    - Data Onboarding
        - Initial Development
        - Perpetual Costs    
---------------------------------------------------------------------------------
#### Tactical Work 
- Centralized MDM - Customer and Product Data stitching: 
    - In-progress solutions
        - Ashwin methodology (Veracity)
        - Syndigo methodology
        - Mackensey methodology
        - Tiger methodology (Lead enrichment pipeline)
    - Need validation framework 
    - Continous process and absorbing revisions? 
    - Cleanup plan for existing data 
    - Prevention plan for further data screwups
---------------------------------------------------------------------------------
#### Design for a data product

- Product Owner
    - What is the output ? Who are the consumers ?
    - What are the required inputs? Do we have it all ? 
    - Can they get it today by other means ?
    - If yes, why build a new solution? 
    - Is there ROI on the cost/time investment ?
    - Get the management approval for the product scope/FRS

- Project Owner 
    - What are the various tasks involved?
    - How many man-hours of effort involved?
    - Team size and skill sets 
    - Task inter-dependencies and order of execution
    - How do split the work and milestone optimally?
    - What are the deliverables at each milestone?  
    - Get the management approval for the project plan 
        - Budget, Timelines and Staffing Plan
     
- Solution Owner
    - Identify the NFRs - add to the requirements
    - Technical Architecture and Design proposal
    - Execution responsibility - Coding, testing, User Acceptance and Production (SDLC)
    - Responsible if it doesnot work, is buggy or doesnot meet the requirements

-------------------------------------------------------------------------------------------------------
