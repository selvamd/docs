## Logical Architecture

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
