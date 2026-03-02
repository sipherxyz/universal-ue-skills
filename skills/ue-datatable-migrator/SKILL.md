---
name: ue-datatable-migrator
description: Migrate DataTable schema changes including column additions, renames, type changes, and row reference updates. Use when evolving DataTable structures, refactoring data schemas, or managing DataTable versioning. Triggers on "datatable migration", "datatable schema", "data table change", "migrate data", "datatable column", "schema migration".
---

# UE DataTable Migrator

Safely migrate DataTable schema changes with reference tracking and validation.

## Quick Start

1. Identify DataTable and required changes
2. Generate migration plan
3. Execute with validation

## Migration Types

| Type | Complexity | Risk |
|------|------------|------|
| Add Column | Low | None |
| Rename Column | Medium | Reference updates |
| Change Type | High | Data conversion |
| Remove Column | Medium | Orphan check |
| Add Row | Low | FK validation |
| Remove Row | High | Reference check |

## Migration Workflow

### Step 1: Analyze Current Schema

```markdown
## DataTable Analysis: DT_{TableName}

### Row Struct: F{StructName}
| Column | Type | Default | Nullable |
|--------|------|---------|----------|
| {Column} | {Type} | {Default} | {Yes/No} |

### Row Count: {N}

### Foreign Key References
| Column | References | Type |
|--------|------------|------|
| {Column} | DT_{OtherTable} | RowName/SoftRef |

### Referenced By
| Table | Column |
|-------|--------|
| DT_{OtherTable} | {Column} |
```

### Step 2: Define Migration

```cpp
// Migration definition
struct FDataTableMigration
{
    // Add column
    void AddColumn(FName ColumnName, FProperty* PropertyType, FString DefaultValue);

    // Rename column
    void RenameColumn(FName OldName, FName NewName);

    // Change type (with converter)
    void ChangeColumnType(FName ColumnName, FProperty* NewType, TFunction<FString(const FString&)> Converter);

    // Remove column (with orphan check)
    void RemoveColumn(FName ColumnName, bool bForce = false);
};
```

### Step 3: Execute Migration

#### Add Column

```markdown
## Add Column: {ColumnName}

### Struct Change
```cpp
// Before
USTRUCT()
struct FEnemyData : public FTableRowBase
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere)
    float Health;
};

// After
USTRUCT()
struct FEnemyData : public FTableRowBase
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere)
    float Health;

    UPROPERTY(EditAnywhere)
    float {ColumnName} = {DefaultValue};  // NEW
};
```

### DataTable Update
- All existing rows get default value
- No data loss
```

#### Rename Column

```markdown
## Rename Column: {OldName} → {NewName}

### Struct Change
```cpp
// Rename property
UPROPERTY(EditAnywhere)
float {NewName};  // Was: {OldName}
```

### Code References to Update
| File | Line | Change |
|------|------|--------|
| {File} | {N} | `Row->{OldName}` → `Row->{NewName}` |

### Blueprint References
| Asset | Node |
|-------|------|
| {BP} | GetDataTableRow → {OldName} |

### Redirector (Optional)
```ini
+PropertyRedirects=(OldName="{OldName}",NewName="{NewName}")
```
```

#### Change Column Type

```markdown
## Change Type: {Column} from {OldType} to {NewType}

### Conversion Strategy
| Old Value | New Value | Rule |
|-----------|-----------|------|
| {Example1} | {Example1} | {Rule} |

### Data Loss Risk
- {Assessment}

### Validation
- [ ] All values convertible
- [ ] No precision loss
- [ ] Range within new type bounds
```

#### Remove Column

```markdown
## Remove Column: {ColumnName}

### Orphan Check
References found:
| Location | Usage |
|----------|-------|
| {File/Asset} | {How it's used} |

### Removal Safe: {Yes/No}
{Explanation}

### Struct Change
```cpp
// Remove property
// UPROPERTY(EditAnywhere)
// float {ColumnName};  // REMOVED
```
```

## Row Operations

### Add Row

```markdown
## Add Row: {RowName}

### Validation
- [ ] RowName unique in table
- [ ] Required fields populated
- [ ] FK references valid

### Row Data
| Column | Value |
|--------|-------|
| {Col} | {Value} |
```

### Remove Row

```markdown
## Remove Row: {RowName}

### Reference Check
Tables referencing this row:
| Table | Column | Rows Affected |
|-------|--------|---------------|
| DT_{Table} | {Col} | {RowNames} |

### Cascade Options
1. **Block** - Prevent removal (references exist)
2. **Nullify** - Set references to None
3. **Cascade** - Remove referencing rows too

### Selected: {Option}
```

## Bulk Operations

### Import from CSV

```markdown
## CSV Import: {FileName}

### Mapping
| CSV Column | DT Column | Type Match |
|------------|-----------|------------|
| {CSVCol} | {DTCol} | {Yes/No} |

### Conflicts
| Row | Existing | Incoming | Resolution |
|-----|----------|----------|------------|
| {Row} | {Value} | {Value} | {Keep/Replace} |
```

### Export for Backup

```cpp
// Export before migration
FString CSVContent;
DataTable->GetTableAsCSV(CSVContent);
FFileHelper::SaveStringToFile(CSVContent, *BackupPath);
```

## Validation

### Pre-Migration Checks

- [ ] Struct compiles with changes
- [ ] No circular FK references
- [ ] Default values valid
- [ ] Type conversions possible

### Post-Migration Checks

- [ ] All rows load correctly
- [ ] FK references resolve
- [ ] No null constraint violations
- [ ] Dependent BPs compile

## Report Template

```markdown
# DataTable Migration Report: DT_{TableName}

## Summary
- **Migration Type**: {Schema/Data/Both}
- **Risk Level**: {Low/Medium/High}
- **Rows Affected**: {N}

## Changes Applied
| Change | Details | Status |
|--------|---------|--------|
| {Change} | {Details} | {Success/Failed} |

## Backup Location
`{BackupPath}`

## Rollback Procedure
1. Delete modified DT_{TableName}
2. Restore from backup
3. Revert struct changes in {StructFile}
4. Recompile

## Validation Results
- Struct Compilation: {Pass/Fail}
- Row Loading: {N}/{Total} successful
- FK Resolution: {Pass/Fail}
- BP Compilation: {Pass/Fail}
```

## Best Practices

1. **Always backup** before migration
2. **Test in isolated branch** first
3. **Validate FK chains** before removal
4. **Use defaults** for new required columns
5. **Document migrations** for team awareness
6. **Version struct changes** with code changes
