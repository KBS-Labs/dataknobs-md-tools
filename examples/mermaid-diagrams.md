# Mermaid Diagram Examples

This document demonstrates various Mermaid diagram types that can be rendered to PDF.

## Flowchart

```mermaid
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
    C --> E[End]
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant System
    participant Database

    User->>System: Request data
    System->>Database: Query
    Database-->>System: Results
    System-->>User: Response
```

## Class Diagram

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
    }

    class Dog {
        +String breed
        +bark()
    }

    class Cat {
        +String color
        +meow()
    }

    Animal <|-- Dog
    Animal <|-- Cat
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Success : Complete
    Processing --> Error : Fail
    Success --> [*]
    Error --> Idle : Retry
```

## Gantt Chart

```mermaid
gantt
    title Project Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1
    Design           :a1, 2024-01-01, 30d
    Implementation   :after a1, 45d
    section Phase 2
    Testing          :2024-03-01, 30d
    Deployment       :2024-04-01, 15d
```

## Pie Chart

```mermaid
pie title Technology Stack
    "Python" : 45
    "JavaScript" : 30
    "Go" : 15
    "Other" : 10
```

## Entity Relationship Diagram

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    PRODUCT ||--o{ LINE-ITEM : includes

    CUSTOMER {
        string name
        string email
        string address
    }

    ORDER {
        int orderNumber
        date orderDate
        string status
    }

    LINE-ITEM {
        int quantity
        float price
    }

    PRODUCT {
        string name
        float unitPrice
        string category
    }
```

## Git Graph

```mermaid
gitGraph
    commit
    commit
    branch develop
    checkout develop
    commit
    commit
    checkout main
    merge develop
    commit
    branch feature
    checkout feature
    commit
    commit
    checkout main
    merge feature
```

## User Journey

```mermaid
journey
    title User Documentation Journey
    section Writing
      Create Markdown: 5: User
      Add Diagrams: 4: User
      Review Content: 3: User
    section Converting
      Run Converter: 5: User
      Generate PDF: 5: System
      View Output: 5: User
    section Sharing
      Upload to GitHub: 4: User
      Share Link: 5: User
      Receive Feedback: 3: User
```

## Regular Markdown Content

The above diagrams demonstrate the various types of visualizations you can include in your markdown documents. When converted to PDF, these will be rendered as static images while maintaining their clarity and structure.

### Benefits of Mermaid Diagrams

1. **Version Control Friendly**: Diagrams are defined in text
2. **Easy to Update**: No need for external drawing tools
3. **Consistent Styling**: Automatic styling based on theme
4. **Documentation as Code**: Keep diagrams with your documentation