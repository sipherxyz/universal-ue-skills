---
name: ue-toolbar-extension
description: Generate boilerplate code for adding custom toolbar buttons to UE5.7 asset editors
---

# UE5.7 Asset Editor Toolbar Extension Skill

## Description
Generate boilerplate code for adding custom toolbar buttons to Unreal Engine 5.7 asset editors (Animation Editor, Material Editor, Blueprint Editor, etc.). Uses the UToolMenus system with dynamic entries for context-aware buttons.

## Usage
```
/ue-toolbar-extension
```

## Prompts

When invoked, ask the user these questions in order:

### 1. Target Asset Editor
Ask: "Which asset editor do you want to extend with a toolbar button?"

Options:
- **Animation Editor** - For AnimSequence, AnimMontage, BlendSpace assets
- **Material Editor** - For Material and MaterialInstance assets
- **Blueprint Editor** - For Blueprint assets
- **Static Mesh Editor** - For StaticMesh assets
- **Skeletal Mesh Editor** - For SkeletalMesh assets
- **Texture Editor** - For Texture2D assets
- **Other** - User specifies custom menu path

### 2. Button Details
Ask: "What should the toolbar button do?"

Gather:
- **Button Name**: Internal name (e.g., "SyncWithTemplate")
- **Display Label**: Shown in UI (e.g., "Sync Template")
- **Tooltip**: Hover description
- **Target Asset Class**: Which asset type to filter for (e.g., UAnimMontage)

### 3. Plugin Context
Ask: "Which plugin/module should this be added to?"

Options:
- Create new toolbar class in existing editor module
- User specifies module name

## Code Generation

After gathering inputs, generate these files:

### File 1: {ToolbarClassName}.h

```cpp
// Copyright [Company]. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

class U{TargetAssetClass};
struct FToolMenuSection;

/**
 * Toolbar extension for {EditorName}.
 * Adds a "{DisplayLabel}" button to the asset editor toolbar.
 *
 * Uses UToolMenus to extend "{MenuPath}"
 */
class {MODULENAME}_API F{ToolbarClassName}
{
public:
    F{ToolbarClassName}();
    ~F{ToolbarClassName}();

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
    void On{ButtonName}Clicked(TWeakObjectPtr<U{TargetAssetClass}> WeakAsset);

    /** Whether we're initialized */
    bool bIsInitialized = false;
};
```

### File 2: {ToolbarClassName}.cpp

```cpp
// Copyright [Company]. All Rights Reserved.

#include "{ToolbarClassName}.h"

#include "{TargetAssetHeader}"
#include "Editor.h"
#include "Styling/AppStyle.h"
#include "ToolMenus.h"
#include "Toolkits/AssetEditorToolkitMenuContext.h"

#define LOCTEXT_NAMESPACE "{ToolbarClassName}"

F{ToolbarClassName}::F{ToolbarClassName}()
{
}

F{ToolbarClassName}::~F{ToolbarClassName}()
{
    Shutdown();
}

void F{ToolbarClassName}::Initialize()
{
    if (bIsInitialized)
    {
        return;
    }

    // Register toolbar extension using UToolMenus
    UToolMenus::RegisterStartupCallback(
        FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &F{ToolbarClassName}::RegisterMenus));

    bIsInitialized = true;
}

void F{ToolbarClassName}::Shutdown()
{
    if (!bIsInitialized)
    {
        return;
    }

    // Unregister from UToolMenus
    UToolMenus::UnRegisterStartupCallback(this);
    UToolMenus::UnregisterOwner(this);

    bIsInitialized = false;
}

void F{ToolbarClassName}::RegisterMenus()
{
    FToolMenuOwnerScoped OwnerScoped(this);

    // Extend the asset editor toolbar
    UToolMenu* Menu = UToolMenus::Get()->ExtendMenu("{MenuPath}");
    if (Menu)
    {
        FToolMenuSection& Section = Menu->FindOrAddSection("{SectionName}");
        Section.Label = LOCTEXT("{SectionName}Label", "{SectionDisplayName}");

        // Use dynamic entry to get access to the editing context
        Section.AddDynamicEntry("{ButtonName}Button",
            FNewToolMenuSectionDelegate::CreateRaw(this, &F{ToolbarClassName}::BuildToolbarEntry));
    }
}

void F{ToolbarClassName}::BuildToolbarEntry(FToolMenuSection& Section)
{
    // Get the context to access the asset being edited
    UAssetEditorToolkitMenuContext* Context = Section.FindContext<UAssetEditorToolkitMenuContext>();
    if (!Context)
    {
        return;
    }

    // Get the editing objects
    TArray<UObject*> EditingObjects = Context->GetEditingObjects();
    if (EditingObjects.Num() == 0)
    {
        return;
    }

    // Check if we're editing the target asset type
    U{TargetAssetClass}* Asset = Cast<U{TargetAssetClass}>(EditingObjects[0]);
    if (!Asset)
    {
        return;
    }

    // Create a weak pointer for the lambda (prevents dangling references)
    TWeakObjectPtr<U{TargetAssetClass}> WeakAsset = Asset;

    // Add the toolbar button
    Section.AddEntry(FToolMenuEntry::InitToolBarButton(
        "{ButtonName}",
        FUIAction(
            FExecuteAction::CreateRaw(this, &F{ToolbarClassName}::On{ButtonName}Clicked, WeakAsset),
            FCanExecuteAction::CreateLambda([WeakAsset]() { return WeakAsset.IsValid(); })
        ),
        LOCTEXT("{ButtonName}", "{DisplayLabel}"),
        LOCTEXT("{ButtonName}Tooltip", "{Tooltip}"),
        FSlateIcon(FAppStyle::GetAppStyleSetName(), "{IconName}")
    ));
}

void F{ToolbarClassName}::On{ButtonName}Clicked(TWeakObjectPtr<U{TargetAssetClass}> WeakAsset)
{
    U{TargetAssetClass}* Asset = WeakAsset.Get();
    if (!Asset)
    {
        return;
    }

    // TODO: Implement your button action here
    // Example: Open a dialog, perform an operation, etc.

    UE_LOG(LogTemp, Log, TEXT("{ButtonName} clicked for asset: %s"), *Asset->GetName());
}

#undef LOCTEXT_NAMESPACE
```

### File 3: Module Integration Snippet

Add to your editor module's header:
```cpp
// Forward declaration
class F{ToolbarClassName};

// In class definition, add member:
TUniquePtr<F{ToolbarClassName}> {ToolbarMemberName};
```

Add to your editor module's StartupModule():
```cpp
// Initialize toolbar extension
{ToolbarMemberName} = MakeUnique<F{ToolbarClassName}>();
{ToolbarMemberName}->Initialize();
```

Add to your editor module's ShutdownModule():
```cpp
// Shutdown toolbar extension
if ({ToolbarMemberName})
{
    {ToolbarMemberName}->Shutdown();
    {ToolbarMemberName}.Reset();
}
```

## Editor Menu Paths Reference

| Editor Type | Menu Path | Common Asset Classes |
|-------------|-----------|---------------------|
| Animation Editor | `AssetEditor.AnimationEditor.ToolBar` | UAnimSequence, UAnimMontage, UBlendSpace |
| Material Editor | `AssetEditor.MaterialEditor.ToolBar` | UMaterial, UMaterialInstance |
| Blueprint Editor | `AssetEditor.BlueprintEditor.ToolBar` | UBlueprint |
| Static Mesh Editor | `AssetEditor.StaticMeshEditor.ToolBar` | UStaticMesh |
| Skeletal Mesh Editor | `AssetEditor.SkeletalMeshEditor.ToolBar` | USkeletalMesh |
| Skeleton Editor | `AssetEditor.SkeletonEditor.ToolBar` | USkeleton |
| Texture Editor | `AssetEditor.TextureEditor.ToolBar` | UTexture2D |
| Sound Wave Editor | `AssetEditor.SoundWaveEditor.ToolBar` | USoundWave |
| Physics Asset Editor | `AssetEditor.PhysicsAssetEditor.ToolBar` | UPhysicsAsset |
| Niagara Editor | `AssetEditor.NiagaraSystemEditor.ToolBar` | UNiagaraSystem |

## Common Icon Names (FAppStyle)

- `Icons.Adjust` - Settings/tweak icon
- `Icons.Edit` - Pencil/edit icon
- `Icons.Plus` - Add/plus icon
- `Icons.Delete` - Delete/trash icon
- `Icons.Refresh` - Refresh/sync icon
- `Icons.Import` - Import arrow icon
- `Icons.Export` - Export arrow icon
- `Icons.Check` - Checkmark icon
- `Icons.Warning` - Warning triangle icon
- `Icons.Info` - Info circle icon

## Required Module Dependencies

Add to your `.Build.cs`:
```csharp
PrivateDependencyModuleNames.AddRange(new string[]
{
    "ToolMenus",
    "UnrealEd",
    "Slate",
    "SlateCore",
    "EditorStyle",
    // Add asset-specific modules as needed:
    // "AnimationEditor",
    // "MaterialEditor",
    // etc.
});
```

## Advanced Patterns

### Adding a Dropdown Menu Instead of Button

```cpp
// In BuildToolbarEntry(), use InitComboButton instead:
Section.AddEntry(FToolMenuEntry::InitComboButton(
    "{ButtonName}",
    FUIAction(),
    FOnGetContent::CreateRaw(this, &F{ToolbarClassName}::GenerateDropdownMenu, WeakAsset),
    LOCTEXT("{ButtonName}", "{DisplayLabel}"),
    LOCTEXT("{ButtonName}Tooltip", "{Tooltip}"),
    FSlateIcon(FAppStyle::GetAppStyleSetName(), "{IconName}")
));

// Add method to generate dropdown content:
TSharedRef<SWidget> F{ToolbarClassName}::GenerateDropdownMenu(TWeakObjectPtr<U{TargetAssetClass}> WeakAsset)
{
    FMenuBuilder MenuBuilder(true, nullptr);

    MenuBuilder.AddMenuEntry(
        LOCTEXT("Option1", "Option 1"),
        LOCTEXT("Option1Tooltip", "Description of option 1"),
        FSlateIcon(),
        FUIAction(FExecuteAction::CreateLambda([WeakAsset]()
        {
            // Handle option 1
        }))
    );

    return MenuBuilder.MakeWidget();
}
```

### Adding a Modal Dialog

See `SMontageTemplateSyncDialog` in `MontageSynchronizerToolbar.cpp` for a complete example of:
- Slate dialog widget with SLATE_BEGIN_ARGS
- ComboBox for selection
- CheckBoxes for options
- Modal window via `GEditor->EditorAddModalWindow()`

## Example: Complete Implementation

Reference implementation:
- [MontageSynchronizerToolbar.h](../../Plugins/Frameworks/SipherMontageStandards/Source/SipherMontageStandardsEditor/Public/MontageSynchronizerToolbar.h)
- [MontageSynchronizerToolbar.cpp](../../Plugins/Frameworks/SipherMontageStandards/Source/SipherMontageStandardsEditor/Private/MontageSynchronizerToolbar.cpp)
- [SipherMontageStandardsEditorModule.cpp](../../Plugins/Frameworks/SipherMontageStandards/Source/SipherMontageStandardsEditor/Private/SipherMontageStandardsEditorModule.cpp)

## Legacy Metadata

```yaml
invoke: /editor-tools:ue-toolbar-extension
```
