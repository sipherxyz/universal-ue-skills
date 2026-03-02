# UE5.7 Asset Editor Menu Paths Reference

Quick reference for extending asset editor toolbars using UToolMenus.

## Asset Editor Toolbar Paths

| Editor | Menu Path | Primary Asset Classes |
|--------|-----------|----------------------|
| Animation Editor | `AssetEditor.AnimationEditor.ToolBar` | UAnimSequence, UAnimMontage, UBlendSpace, UAnimComposite |
| Material Editor | `AssetEditor.MaterialEditor.ToolBar` | UMaterial, UMaterialInstance, UMaterialFunction |
| Blueprint Editor | `AssetEditor.BlueprintEditor.ToolBar` | UBlueprint, UWidgetBlueprint |
| Static Mesh Editor | `AssetEditor.StaticMeshEditor.ToolBar` | UStaticMesh |
| Skeletal Mesh Editor | `AssetEditor.SkeletalMeshEditor.ToolBar` | USkeletalMesh |
| Skeleton Editor | `AssetEditor.SkeletonEditor.ToolBar` | USkeleton |
| Texture Editor | `AssetEditor.TextureEditor.ToolBar` | UTexture2D, UTextureCube, UTextureRenderTarget2D |
| Sound Wave Editor | `AssetEditor.SoundWaveEditor.ToolBar` | USoundWave |
| Physics Asset Editor | `AssetEditor.PhysicsAssetEditor.ToolBar` | UPhysicsAsset |
| Niagara System | `AssetEditor.NiagaraSystemEditor.ToolBar` | UNiagaraSystem |
| Niagara Emitter | `AssetEditor.NiagaraEmitterEditor.ToolBar` | UNiagaraEmitter |
| Behavior Tree | `AssetEditor.BehaviorTreeEditor.ToolBar` | UBehaviorTree |
| State Tree | `AssetEditor.StateTreeEditor.ToolBar` | UStateTree |
| Control Rig | `AssetEditor.ControlRigEditor.ToolBar` | UControlRigBlueprint |
| Animation Blueprint | `AssetEditor.AnimationBlueprintEditor.ToolBar` | UAnimBlueprint |
| Data Asset | `AssetEditor.DataAssetEditor.ToolBar` | UDataAsset (and subclasses) |
| Curve | `AssetEditor.CurveAssetEditor.ToolBar` | UCurveFloat, UCurveVector, UCurveLinearColor |

## Common Header Includes by Asset Type

```cpp
// Animation
#include "Animation/AnimSequence.h"
#include "Animation/AnimMontage.h"
#include "Animation/BlendSpace.h"

// Materials
#include "Materials/Material.h"
#include "Materials/MaterialInstance.h"

// Meshes
#include "Engine/StaticMesh.h"
#include "Engine/SkeletalMesh.h"

// Blueprints
#include "Engine/Blueprint.h"
#include "WidgetBlueprint.h"

// AI
#include "BehaviorTree/BehaviorTree.h"
#include "StateTree.h"

// Audio
#include "Sound/SoundWave.h"

// Textures
#include "Engine/Texture2D.h"

// Niagara
#include "NiagaraSystem.h"
#include "NiagaraEmitter.h"
```

## FSlateIcon Names (FAppStyle)

### Action Icons
- `Icons.Plus` - Add/create
- `Icons.Delete` - Remove/delete
- `Icons.Edit` - Edit/modify
- `Icons.Duplicate` - Copy/duplicate
- `Icons.Refresh` - Refresh/reload
- `Icons.Check` - Confirm/validate

### State Icons
- `Icons.Warning` - Warning state
- `Icons.Error` - Error state
- `Icons.Info` - Information
- `Icons.Help` - Help/documentation

### Tool Icons
- `Icons.Adjust` - Settings/configure
- `Icons.Filter` - Filter/search
- `Icons.Import` - Import data
- `Icons.Export` - Export data
- `Icons.Download` - Download
- `Icons.Upload` - Upload
- `Icons.Lock` - Locked state
- `Icons.Unlock` - Unlocked state

### Media Icons
- `Icons.Play` - Play
- `Icons.Stop` - Stop
- `Icons.Pause` - Pause

### Navigation Icons
- `Icons.ArrowLeft` - Previous/back
- `Icons.ArrowRight` - Next/forward
- `Icons.ArrowUp` - Up
- `Icons.ArrowDown` - Down

## Context Class Usage

All asset editors use `UAssetEditorToolkitMenuContext`:

```cpp
void BuildToolbarEntry(FToolMenuSection& Section)
{
    UAssetEditorToolkitMenuContext* Context = Section.FindContext<UAssetEditorToolkitMenuContext>();
    if (!Context) return;

    TArray<UObject*> EditingObjects = Context->GetEditingObjects();
    // EditingObjects[0] is the primary asset being edited
}
```

## Build.cs Dependencies

Required modules for toolbar extensions:

```csharp
PrivateDependencyModuleNames.AddRange(new string[]
{
    // Core toolbar functionality
    "ToolMenus",
    "UnrealEd",
    "Slate",
    "SlateCore",

    // For FAppStyle icons
    "EditorStyle",

    // Asset Registry (if querying assets)
    "AssetRegistry",

    // Editor-specific (add as needed)
    "AnimationEditor",        // Animation assets
    "MaterialEditor",         // Material assets
    "Kismet",                 // Blueprint editor
    "StaticMeshEditor",       // Static mesh
    "SkeletalMeshEditor",     // Skeletal mesh
    "BehaviorTreeEditor",     // Behavior trees
    "StateTreeEditorModule",  // State trees
    "NiagaraEditor",          // Niagara systems
});
```

## Discovering Menu Paths

To discover menu paths at runtime, add this debug code:

```cpp
// In your module's StartupModule()
#if WITH_EDITOR
if (GIsEditor)
{
    UToolMenus::Get()->RegisterStringCommandHandler(
        "DebugPrintMenus",
        FToolMenuStringCommand::CreateLambda([](const FString& InCommand)
        {
            TArray<FName> MenuNames;
            UToolMenus::Get()->CollectAllMenuNames(MenuNames);
            for (const FName& Name : MenuNames)
            {
                if (Name.ToString().Contains("AssetEditor"))
                {
                    UE_LOG(LogTemp, Log, TEXT("Menu: %s"), *Name.ToString());
                }
            }
        })
    );
}
#endif
```

Or use the console command: `ToolMenus.Edit` to open the Tool Menus editor.
