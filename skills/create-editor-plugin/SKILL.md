---
name: create-editor-plugin
description: Create a new Unreal Engine 5.7 editor-only plugin with proper structure and patterns
---

# Create UE5.7 Editor Plugin Skill

**Purpose:** Generate a complete, production-ready UE5.7 editor plugin skeleton with proper folder structure, module configuration, and best practices.

**Engine Version:** Unreal Engine 5.7.1
**Plugin Type:** Editor-only (Type: "Editor")

## Usage

```
/create-editor-plugin
```

## Workflow

When invoked, gather the following information from the user:

### 1. Plugin Identity
Ask: "What is the name and purpose of this plugin?"

Gather:
- **Plugin Name**: PascalCase, no spaces (e.g., `GameplayTagDataTableExporter`)
- **Friendly Name**: Human-readable display name (e.g., `Gameplay Tag DataTable Exporter`)
- **Description**: One-line description of what the plugin does
- **Author**: Creator name (default: team name from CLAUDE.md)

### 2. Plugin Category
Ask: "What category best describes this plugin?"

Options:
- **Editor Tools** - General editor utilities and QoL tools
- **Content Creation** - Asset creation/validation tools
- **Debugging** - Debug visualization and diagnostics
- **Automation** - Batch processing and automation
- **Integration** - Third-party tool integration
- **Other** - User specifies custom category

### 3. Plugin Location
Ask: "Where should this plugin be created?"

Options:
- `Plugins/EditorTools/` - General editor tools (Recommended)
- `Plugins/Frameworks/` - Framework-level plugins with broader scope
- `Plugins/Marketplace/` - For external distribution
- Custom path - User specifies

### 4. Feature Requirements
Ask: "What features does this plugin need?" (Multi-select)

Options:
- **Toolbar Button** - Add button to asset editor toolbar
- **Menu Entry** - Add entry to Tools menu
- **Details Customization** - Custom property panel for specific types
- **Asset Actions** - Context menu actions for Content Browser
- **Slate Window** - Custom dockable window/tab
- **Commandlet** - Command-line batch processing

## Generated Structure

```
{PluginLocation}/{PluginName}/
├── {PluginName}.uplugin
├── Source/
│   └── {PluginName}/
│       ├── {PluginName}.Build.cs
│       ├── Public/
│       │   └── {PluginName}Module.h
│       └── Private/
│           └── {PluginName}Module.cpp
└── Resources/
    └── Icon128.png (placeholder)
```

## Template Files

### 1. {PluginName}.uplugin

```json
{
    "FileVersion": 3,
    "Version": 1,
    "VersionName": "1.0",
    "FriendlyName": "{FriendlyName}",
    "Description": "{Description}",
    "Category": "{Category}",
    "CreatedBy": "{Author}",
    "CreatedByURL": "",
    "DocsURL": "",
    "MarketplaceURL": "",
    "SupportURL": "",
    "CanContainContent": false,
    "IsBetaVersion": false,
    "IsExperimentalVersion": false,
    "Installed": false,
    "Modules": [
        {
            "Name": "{PluginName}",
            "Type": "Editor",
            "LoadingPhase": "PostEngineInit"
        }
    ]
}
```

### 2. {PluginName}.Build.cs

```csharp
// Copyright Ather Labs, Inc. All Rights Reserved.

using UnrealBuildTool;

public class {PluginName} : ModuleRules
{
    public {PluginName}(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[]
        {
            "Core",
            "CoreUObject",
            "Engine"
        });

        PrivateDependencyModuleNames.AddRange(new string[]
        {
            "Slate",
            "SlateCore",
            "UnrealEd",
            "ToolMenus",
            "InputCore"
        });

        // Add feature-specific dependencies below
        // Example: "GameplayTags", "AssetRegistry", "PropertyEditor"
    }
}
```

### 3. {PluginName}Module.h

```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

// Forward declarations for feature classes
// class F{FeatureName}Toolbar;
// class F{FeatureName}MenuExtension;

/**
 * {Description}
 */
class F{PluginName}Module : public IModuleInterface
{
public:
    /** IModuleInterface implementation */
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;

    /** Get the module instance */
    static F{PluginName}Module& Get();

private:
    /** Register menu extensions with UToolMenus */
    void RegisterMenus();

    // Feature instances
    // TUniquePtr<F{FeatureName}Toolbar> {FeatureName}Toolbar;
};
```

### 4. {PluginName}Module.cpp

```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

#include "{PluginName}Module.h"
#include "ToolMenus.h"

#define LOCTEXT_NAMESPACE "F{PluginName}Module"

void F{PluginName}Module::StartupModule()
{
    // Register menus after UToolMenus is ready
    UToolMenus::RegisterStartupCallback(
        FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &F{PluginName}Module::RegisterMenus));

    // Initialize feature classes
    // {FeatureName}Toolbar = MakeUnique<F{FeatureName}Toolbar>();
    // {FeatureName}Toolbar->Initialize();
}

void F{PluginName}Module::ShutdownModule()
{
    // Cleanup feature classes
    // if ({FeatureName}Toolbar)
    // {
    //     {FeatureName}Toolbar->Shutdown();
    //     {FeatureName}Toolbar.Reset();
    // }

    // Unregister menus
    UToolMenus::UnRegisterStartupCallback(this);
    UToolMenus::UnregisterOwner(this);
}

F{PluginName}Module& F{PluginName}Module::Get()
{
    return FModuleManager::LoadModuleChecked<F{PluginName}Module>("{PluginName}");
}

void F{PluginName}Module::RegisterMenus()
{
    FToolMenuOwnerScoped OwnerScoped(this);

    // Example: Add to Tools menu
    // UToolMenu* Menu = UToolMenus::Get()->ExtendMenu("LevelEditor.MainMenu.Tools");
    // if (Menu)
    // {
    //     FToolMenuSection& Section = Menu->FindOrAddSection("{PluginName}");
    //     Section.Label = LOCTEXT("{PluginName}Section", "{FriendlyName}");
    //
    //     Section.AddMenuEntry(
    //         "{ActionName}",
    //         LOCTEXT("{ActionName}Label", "Action Label"),
    //         LOCTEXT("{ActionName}Tooltip", "Action tooltip description"),
    //         FSlateIcon(FAppStyle::GetAppStyleSetName(), "Icons.Edit"),
    //         FUIAction(FExecuteAction::CreateRaw(this, &F{PluginName}Module::On{ActionName}Executed))
    //     );
    // }
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(F{PluginName}Module, {PluginName})
```

## Feature Templates

### Toolbar Extension (for Asset Editors)

When "Toolbar Button" is selected, also generate:

**{FeatureName}Toolbar.h:**
```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

struct FToolMenuSection;

/**
 * Toolbar extension for {AssetEditor}.
 * Adds a "{ButtonLabel}" button to the asset editor toolbar.
 */
class {MODULENAME}_API F{FeatureName}Toolbar
{
public:
    F{FeatureName}Toolbar();
    ~F{FeatureName}Toolbar();

    /** Initialize and register toolbar extension */
    void Initialize();

    /** Cleanup and unregister */
    void Shutdown();

private:
    /** Register menus with UToolMenus */
    void RegisterMenus();

    /** Build the toolbar entry dynamically based on editing context */
    void BuildToolbarEntry(FToolMenuSection& Section);

    /** Execute action when button is clicked */
    void OnButtonClicked(TWeakObjectPtr<UObject> WeakAsset);

    bool bIsInitialized = false;
};
```

**{FeatureName}Toolbar.cpp:**
```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

#include "{FeatureName}Toolbar.h"
#include "Editor.h"
#include "Styling/AppStyle.h"
#include "ToolMenus.h"
#include "Toolkits/AssetEditorToolkitMenuContext.h"

#define LOCTEXT_NAMESPACE "F{FeatureName}Toolbar"

F{FeatureName}Toolbar::F{FeatureName}Toolbar()
{
}

F{FeatureName}Toolbar::~F{FeatureName}Toolbar()
{
    Shutdown();
}

void F{FeatureName}Toolbar::Initialize()
{
    if (bIsInitialized)
    {
        return;
    }

    UToolMenus::RegisterStartupCallback(
        FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &F{FeatureName}Toolbar::RegisterMenus));

    bIsInitialized = true;
}

void F{FeatureName}Toolbar::Shutdown()
{
    if (!bIsInitialized)
    {
        return;
    }

    UToolMenus::UnRegisterStartupCallback(this);
    UToolMenus::UnregisterOwner(this);

    bIsInitialized = false;
}

void F{FeatureName}Toolbar::RegisterMenus()
{
    FToolMenuOwnerScoped OwnerScoped(this);

    // Extend the asset editor toolbar
    // See EDITOR_MENU_PATHS reference for correct menu path
    UToolMenu* Menu = UToolMenus::Get()->ExtendMenu("AssetEditor.{EditorType}.ToolBar");
    if (Menu)
    {
        FToolMenuSection& Section = Menu->FindOrAddSection("{SectionName}");
        Section.Label = LOCTEXT("{SectionName}Label", "{SectionDisplayName}");

        // Use dynamic entry to get access to the editing context
        Section.AddDynamicEntry("{ButtonName}Button",
            FNewToolMenuSectionDelegate::CreateRaw(this, &F{FeatureName}Toolbar::BuildToolbarEntry));
    }
}

void F{FeatureName}Toolbar::BuildToolbarEntry(FToolMenuSection& Section)
{
    UAssetEditorToolkitMenuContext* Context = Section.FindContext<UAssetEditorToolkitMenuContext>();
    if (!Context)
    {
        return;
    }

    TArray<UObject*> EditingObjects = Context->GetEditingObjects();
    if (EditingObjects.Num() == 0)
    {
        return;
    }

    // Filter for target asset type
    UObject* Asset = EditingObjects[0];
    // U{TargetAssetClass}* TypedAsset = Cast<U{TargetAssetClass}>(Asset);
    // if (!TypedAsset) return;

    TWeakObjectPtr<UObject> WeakAsset = Asset;

    Section.AddEntry(FToolMenuEntry::InitToolBarButton(
        "{ButtonName}",
        FUIAction(
            FExecuteAction::CreateRaw(this, &F{FeatureName}Toolbar::OnButtonClicked, WeakAsset),
            FCanExecuteAction::CreateLambda([WeakAsset]() { return WeakAsset.IsValid(); })
        ),
        LOCTEXT("{ButtonName}", "{ButtonLabel}"),
        LOCTEXT("{ButtonName}Tooltip", "{ButtonTooltip}"),
        FSlateIcon(FAppStyle::GetAppStyleSetName(), "Icons.Edit")
    ));
}

void F{FeatureName}Toolbar::OnButtonClicked(TWeakObjectPtr<UObject> WeakAsset)
{
    UObject* Asset = WeakAsset.Get();
    if (!Asset)
    {
        return;
    }

    // TODO: Implement button action
    UE_LOG(LogTemp, Log, TEXT("{ButtonName} clicked for asset: %s"), *Asset->GetName());
}

#undef LOCTEXT_NAMESPACE
```

### Slate Window Template

When "Slate Window" is selected, also generate:

**S{WindowName}Window.h:**
```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Widgets/SCompoundWidget.h"

/**
 * {WindowDescription}
 */
class {MODULENAME}_API S{WindowName}Window : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(S{WindowName}Window) {}
    SLATE_END_ARGS()

    void Construct(const FArguments& InArgs);

private:
    /** Build the window content */
    TSharedRef<SWidget> BuildContent();

    /** Handle close button */
    FReply OnCloseClicked();
};
```

## Editor Menu Paths Reference

| Editor Type | Menu Path | Common Asset Classes |
|-------------|-----------|---------------------|
| DataTable Editor | `AssetEditor.DataTableEditor.ToolBar` | UDataTable |
| Animation Editor | `AssetEditor.AnimationEditor.ToolBar` | UAnimSequence, UAnimMontage |
| Material Editor | `AssetEditor.MaterialEditor.ToolBar` | UMaterial, UMaterialInstance |
| Blueprint Editor | `AssetEditor.BlueprintEditor.ToolBar` | UBlueprint |
| Static Mesh Editor | `AssetEditor.StaticMeshEditor.ToolBar` | UStaticMesh |
| Skeletal Mesh Editor | `AssetEditor.SkeletalMeshEditor.ToolBar` | USkeletalMesh |
| Texture Editor | `AssetEditor.TextureEditor.ToolBar` | UTexture2D |
| Niagara Editor | `AssetEditor.NiagaraSystemEditor.ToolBar` | UNiagaraSystem |
| Level Editor Tools | `LevelEditor.MainMenu.Tools` | N/A |
| Level Editor Toolbar | `LevelEditor.LevelEditorToolBar.PlayToolBar` | N/A |

## Common Icon Names (FAppStyle)

| Icon | Usage |
|------|-------|
| `Icons.Edit` | Edit/modify actions |
| `Icons.Plus` | Add/create actions |
| `Icons.Delete` | Delete/remove actions |
| `Icons.Refresh` | Refresh/sync actions |
| `Icons.Import` | Import actions |
| `Icons.Export` | Export actions |
| `Icons.Check` | Validation/confirm |
| `Icons.Warning` | Warning indicators |
| `Icons.Info` | Information display |
| `Icons.Settings` | Settings/configuration |

## Common Module Dependencies

| Feature | Required Modules |
|---------|-----------------|
| Toolbar Extension | `ToolMenus`, `UnrealEd`, `Slate`, `SlateCore` |
| Details Panel | `PropertyEditor`, `UnrealEd` |
| Content Browser Actions | `ContentBrowser`, `AssetRegistry` |
| Slate Windows | `Slate`, `SlateCore`, `InputCore` |
| Blueprint Support | `BlueprintGraph`, `Kismet` |
| Gameplay Systems | `GameplayTags`, `GameplayAbilities` |
| AI Support | `AIModule`, `BehaviorTreeEditor` |

## Post-Creation Steps

After generating the plugin:

1. **Add to S2.uproject** (if needed):
   ```json
   {
       "Name": "{PluginName}",
       "Enabled": true
   }
   ```

2. **Regenerate project files**:
   ```bash
   # From project root, run GenerateProjectFiles.bat
   ```

3. **Build the module**:
   ```bash
   /dev-workflow:ue-cpp-build -Module={PluginName}
   ```

4. **Test in editor**:
   - Open Unreal Editor
   - Verify plugin appears in Edit > Plugins
   - Test toolbar/menu integrations

## Best Practices

### DO:
- Use `TWeakObjectPtr` for asset references in lambdas
- Use `FToolMenuOwnerScoped` for menu registration
- Use `LOCTEXT` for all user-facing strings
- Use `FAppStyle` for icons (not deprecated `FEditorStyle`)
- Validate all UObject pointers with `IsValid()` or null checks
- Unregister menus in `ShutdownModule()`

### DON'T:
- Use raw pointers in UI callbacks (memory safety)
- Assume assets exist without validation
- Use synchronous loading in runtime code (editor-only is OK)
- Forget to cleanup in `ShutdownModule()`
- Use `LogTemp` for plugin logging (create dedicated log category)

## Example Reference Implementation

See `Plugins/EditorTools/GameplayTagDataTableExporter/` for a complete working example:
- `GameplayTagDataTableExporter.uplugin` - Plugin descriptor
- `GameplayTagDataTableExporter.Build.cs` - Module rules
- `GameplayTagDataTableExporterModule.h/.cpp` - Module entry point
- `GameplayTagExporterToolbar.h/.cpp` - Toolbar extension pattern

## Related Skills

- `/ue-toolbar-extension` - Add toolbar buttons to existing editors
- `/ue-editor-tools` - General editor tool development patterns
- `/huli-bp-tools` - Blueprint tool development patterns

## Legacy Metadata

```yaml
skill: create-editor-plugin
invoke: /editor-tools:create-editor-plugin
type: implementation
category: editor-tools
scope: Plugins/EditorTools/
```
