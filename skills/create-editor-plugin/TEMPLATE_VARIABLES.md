# Template Variables Reference

This document lists all template variables used in the `create-editor-plugin` skill templates.

## Core Plugin Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{MODULE_NAME}}` | PascalCase module name | `GameplayTagDataTableExporter` |
| `{{FRIENDLY_NAME}}` | Human-readable display name | `Gameplay Tag DataTable Exporter` |
| `{{DESCRIPTION}}` | One-line plugin description | `Export GameplayTag DataTables to C++` |
| `{{CATEGORY}}` | Plugin category | `Editor` |
| `{{AUTHOR}}` | Creator name | `DuyTranSipher` |
| `{{MODULE_API}}` | Module export macro | `GAMEPLAYTAGDATATABLEEXPORTER_API` |

## Toolbar Extension Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{TOOLBAR_CLASS_NAME}}` | Toolbar class name | `GameplayTagExporterToolbar` |
| `{{EDITOR_NAME}}` | Target editor name | `DataTable Editor` |
| `{{MENU_PATH}}` | UToolMenus menu path | `AssetEditor.DataTableEditor.ToolBar` |
| `{{SECTION_NAME}}` | Toolbar section identifier | `GameplayTagExporter` |
| `{{SECTION_DISPLAY_NAME}}` | Section display label | `Export Tools` |
| `{{BUTTON_NAME}}` | Button internal name | `ExportTags` |
| `{{BUTTON_LABEL}}` | Button display text | `Export Tags` |
| `{{BUTTON_TOOLTIP}}` | Button hover tooltip | `Export tags to C++ header` |
| `{{ICON_NAME}}` | FAppStyle icon name | `Icons.Export` |
| `{{TARGET_ASSET_CLASS}}` | Asset class name (no U prefix) | `DataTable` |
| `{{TARGET_ASSET_HEADER}}` | Asset header include | `Engine/DataTable.h` |

## Slate Window Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{WINDOW_NAME}}` | Window class name suffix | `TagExporter` |
| `{{WINDOW_DISPLAY_NAME}}` | Window title | `Export Gameplay Tags` |
| `{{WINDOW_DESCRIPTION}}` | Class documentation | `Dialog for exporting tags` |
| `{{WINDOW_WIDTH}}` | Initial width in pixels | `400` |
| `{{WINDOW_HEIGHT}}` | Initial height in pixels | `300` |
| `{{CONTENT_HEADER}}` | Content section header | `Export Settings` |

## Feature Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{FEATURE_NAME}}` | Feature class name prefix | `TagExporter` |
| `{{ACTION_NAME}}` | Menu action identifier | `ExportTags` |

## Usage

When generating code from templates, replace all `{{VARIABLE}}` placeholders with the appropriate values gathered from user input.

### Example Replacement

**Input:**
```cpp
class F{{MODULE_NAME}}Module : public IModuleInterface
```

**With variables:**
- `MODULE_NAME` = `GameplayTagDataTableExporter`

**Output:**
```cpp
class FGameplayTagDataTableExporterModule : public IModuleInterface
```
