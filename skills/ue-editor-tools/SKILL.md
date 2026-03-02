---
name: ue-editor-tools
description: Create QoL editor tools for Game Designers, QA Combat Testers, and Enemy/AI Content Makers
---

# Unreal Engine Editor Tools Development Skill

**Role:** Editor Tools Engineer
**Target Users:** Game Designers, QA Combat Testers, Enemy AI Content Makers
**Scope:** Editor-only plugins and tools
**Engine Version:** UE 5.7.1
**Quality Standard:** Production-ready, user-friendly UI

## Objective

Design and implement Quality of Life (QoL) editor tools that streamline workflows for:
1. **Game Designers** - Balance tuning, parameter adjustment, rapid iteration
2. **QA Combat Testers** - Damage testing, hitbox visualization, combo validation
3. **Enemy AI Content Makers** - Behavior debugging, AI state visualization, encounter setup

## Tool Categories

### 1. Combat Testing Tools

#### Combat Debug HUD
**Purpose:** Real-time combat data visualization for QA testers

**Features:**
- Damage numbers overlay (incoming/outgoing)
- Hitbox visualization toggle
- Combo state display
- Parry window indicator
- Frame data display (startup, active, recovery)
- Hit reaction state tracking

**Implementation Approach:**
```cpp
// UCombatDebugHUDComponent - Add to player/AI
UCLASS()
class SIPHERDEBUGTOOLS_API UCombatDebugHUDComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDamageNumbers = true;

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowHitboxes = false;

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowComboState = true;

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowFrameData = false;

    // Methods
    void DrawDebugHUD(UCanvas* Canvas, APlayerController* PC);
    void OnDamageReceived(float Damage, AActor* Source);
    void OnComboStateChanged(int32 ComboIndex, FName ComboName);
};
```

#### Damage Calculator Window
**Purpose:** Calculate and compare damage values with different configurations

**Features:**
- Input attacker/defender stats
- Preview damage with various modifiers
- Compare multiple configurations side-by-side
- Export damage reports

#### Hitbox Visualizer
**Purpose:** See all active hitboxes in real-time

**Features:**
- Color-coded by damage type
- Show active frames
- Collision channel display
- Screenshot/record functionality

### 2. AI Testing Tools

#### AI Behavior Debugger
**Purpose:** Visualize and debug AI decision-making

**Features:**
- State Tree current state display
- Behavior Tree active node highlighting
- Blackboard value inspector
- Decision history log
- Force state transitions (debug only)

**Implementation Approach:**
```cpp
// SAIBehaviorDebugWidget - Slate window
class SIPHERDEBUGTOOLS_API SAIBehaviorDebugWidget : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SAIBehaviorDebugWidget) {}
        SLATE_ARGUMENT(TWeakObjectPtr<AAIController>, TargetAI)
    SLATE_END_ARGS()

    void Construct(const FArguments& InArgs);
    void Tick(const FGeometry& AllottedGeometry, double InCurrentTime, float InDeltaTime) override;

private:
    TSharedRef<SWidget> BuildStateTreeView();
    TSharedRef<SWidget> BuildBehaviorTreeView();
    TSharedRef<SWidget> BuildBlackboardView();

    void RefreshAIState();
    FText GetCurrentStateName() const;
    FText GetActiveTaskName() const;
};
```

#### Encounter Designer Tool
**Purpose:** Rapid encounter setup and testing

**Features:**
- Spawn enemy presets at cursor
- Configure spawn waves
- Set encounter triggers
- Save/load encounter configurations
- One-click encounter test (spawns enemies immediately)

#### AI Spawn Tool
**Purpose:** Quick enemy spawning for testing

**Features:**
- Enemy type dropdown (from Data Assets)
- Spawn at location picker
- Team assignment
- Initial state override (patrol, combat, idle)
- Spawn count slider

### 3. Designer Tools

#### Parameter Tuning Panel
**Purpose:** Live-edit gameplay parameters without code changes

**Features:**
- Browse all Data Assets
- Edit values in real-time
- Preview changes without restart
- Revert to defaults
- Save as new preset

**Implementation Approach:**
```cpp
// FParameterTuningModule - Editor module
class SIPHERDESIGNERTOOLS_API FParameterTuningModule : public IModuleInterface
{
public:
    void StartupModule() override;
    void ShutdownModule() override;

private:
    void OpenParameterWindow();

    TSharedPtr<SDockTab> ParameterTab;
};

// SParameterTuningWidget - Main widget
class SParameterTuningWidget : public SCompoundWidget
{
    // Asset browser for Data Assets
    TSharedPtr<SAssetSearchBox> AssetSearch;
    TSharedPtr<IDetailsView> DetailsView;

    void OnAssetSelected(const FAssetData& AssetData);
    void OnPropertyChanged(const FPropertyChangedEvent& Event);
    void ApplyChangesToRunningGame();
};
```

#### Combo Graph Tester
**Purpose:** Test combo sequences without playing the game

**Features:**
- Visual combo tree display
- Input sequence simulator
- Transition validation
- Missing connection detection
- Export combo documentation

#### Ability Tester Window
**Purpose:** Test GAS abilities in isolation

**Features:**
- Select ability from dropdown
- Configure ability parameters
- Execute with mock Actor
- View gameplay effects applied
- Log output panel

### 4. Content Creation Tools

#### Enemy Blueprint Validator
**Purpose:** Validate enemy Blueprints have required components

**Features:**
- Check for required components (ASC, AI Controller, etc.)
- Verify Data Asset references are set
- Check animation montage assignments
- Validate Behavior Tree assignments
- Generate validation report

**Implementation Approach:**
```cpp
UCLASS()
class SIPHERCONTENTTOOLS_API UEnemyBlueprintValidator : public UObject
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Validation")
    static FValidationResult ValidateEnemyBlueprint(UBlueprint* Blueprint);

    // Validation rules
    static bool HasRequiredComponent(UBlueprint* BP, TSubclassOf<UActorComponent> ComponentClass);
    static bool HasValidBehaviorTree(UBlueprint* BP);
    static bool HasValidAnimMontages(UBlueprint* BP);
    static bool HasValidDataAsset(UBlueprint* BP);
};
```

#### Animation Montage Browser
**Purpose:** Browse and preview montages for specific characters

**Features:**
- Filter by character/skeleton
- Preview in viewport
- Show notify tracks
- Copy montage references
- Quick assign to abilities

#### Data Asset Creator Wizard
**Purpose:** Guided creation of common Data Assets

**Features:**
- Step-by-step wizard
- Templates for common types (Enemy Profile, Ability Data, etc.)
- Auto-fill common values
- Validation before creation

## Plugin Structure

### Recommended Plugin Organization

```
Plugins/Frameworks/SipherEditorTools/
├── SipherEditorTools.uplugin
├── Source/
│   ├── SipherEditorTools/
│   │   ├── Public/
│   │   │   ├── SipherEditorToolsModule.h
│   │   │   ├── Combat/
│   │   │   │   ├── SCombatDebugHUD.h
│   │   │   │   ├── SDamageCalculator.h
│   │   │   │   └── SHitboxVisualizer.h
│   │   │   ├── AI/
│   │   │   │   ├── SAIBehaviorDebugger.h
│   │   │   │   ├── SEncounterDesigner.h
│   │   │   │   └── SAISpawnTool.h
│   │   │   ├── Designer/
│   │   │   │   ├── SParameterTuning.h
│   │   │   │   ├── SComboGraphTester.h
│   │   │   │   └── SAbilityTester.h
│   │   │   └── Content/
│   │   │       ├── SEnemyValidator.h
│   │   │       ├── SMontagesBrowser.h
│   │   │       └── SDataAssetWizard.h
│   │   └── Private/
│   │       ├── SipherEditorToolsModule.cpp
│   │       ├── Combat/
│   │       ├── AI/
│   │       ├── Designer/
│   │       └── Content/
│   └── SipherEditorTools.Build.cs
└── Resources/
    └── Icon128.png
```

### Build.cs Template

```csharp
using UnrealBuildTool;

public class SipherEditorTools : ModuleRules
{
    public SipherEditorTools(ReadOnlyTargetRules Target) : base(Target)
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
            "UnrealEd",
            "Slate",
            "SlateCore",
            "EditorStyle",
            "InputCore",
            "ToolMenus",
            "PropertyEditor",
            "AssetRegistry",
            "ContentBrowser",
            "BlueprintGraph",
            "Kismet",
            // Game modules
            "S2",
            "SipherComboGraphRuntime",
            "SipherAIScalableFramework",
            "GameplayAbilities",
            "GameplayTags",
            "AIModule"
        });

        // Editor-only module
        if (Target.Type == TargetType.Editor)
        {
            PrivateDependencyModuleNames.Add("EditorFramework");
            PrivateDependencyModuleNames.Add("WorkspaceMenuStructure");
        }
    }
}
```

### .uplugin Template

```json
{
    "FileVersion": 3,
    "Version": 1,
    "VersionName": "1.0",
    "FriendlyName": "Sipher Editor Tools",
    "Description": "QoL tools for designers, QA, and content creators",
    "Category": "Editor",
    "CreatedBy": "Sipher Team",
    "CreatedByURL": "",
    "DocsURL": "",
    "MarketplaceURL": "",
    "SupportURL": "",
    "EnabledByDefault": true,
    "CanContainContent": true,
    "IsBetaVersion": false,
    "IsExperimentalVersion": false,
    "Installed": false,
    "Modules": [
        {
            "Name": "SipherEditorTools",
            "Type": "Editor",
            "LoadingPhase": "Default"
        }
    ]
}
```

## UI/UX Guidelines

### Slate Best Practices

```cpp
// Use consistent spacing
const float StandardPadding = 4.0f;
const float SectionPadding = 8.0f;

// Use FSlateIcon for tool buttons
FSlateIcon(FAppStyle::GetAppStyleSetName(), "Icons.Edit")

// Consistent button styling
SNew(SButton)
    .ButtonStyle(FAppStyle::Get(), "FlatButton.Success")
    .ContentPadding(FMargin(4.0f, 2.0f))

// Use expandable sections for organization
SNew(SExpandableArea)
    .AreaTitle(LOCTEXT("SectionTitle", "Section Name"))
    .InitiallyCollapsed(false)
    .BodyContent(...)
```

### Menu Integration

```cpp
// Add to Tools menu
UToolMenu* ToolsMenu = UToolMenus::Get()->ExtendMenu("LevelEditor.MainMenu.Tools");

FToolMenuSection& Section = ToolsMenu->FindOrAddSection("SipherTools");
Section.Label = LOCTEXT("SipherToolsSection", "Sipher Tools");

Section.AddSubMenu(
    "CombatTools",
    LOCTEXT("CombatToolsMenu", "Combat Tools"),
    LOCTEXT("CombatToolsTooltip", "Tools for combat testing"),
    FNewToolMenuDelegate::CreateLambda([](UToolMenu* SubMenu)
    {
        FToolMenuSection& SubSection = SubMenu->AddSection("CombatSection");
        SubSection.AddMenuEntry(...);
    })
);
```

### Toolbar Integration

```cpp
// Add toolbar button
UToolMenu* Toolbar = UToolMenus::Get()->ExtendMenu("LevelEditor.LevelEditorToolBar.PlayToolBar");

FToolMenuSection& Section = Toolbar->FindOrAddSection("SipherQuickTools");
Section.AddEntry(FToolMenuEntry::InitToolBarButton(
    "SpawnEnemy",
    FUIAction(FExecuteAction::CreateLambda([]() { /* spawn logic */ })),
    LOCTEXT("SpawnEnemy", "Spawn Enemy"),
    LOCTEXT("SpawnEnemyTooltip", "Quick spawn enemy at cursor"),
    FSlateIcon(FAppStyle::GetAppStyleSetName(), "Icons.Plus")
));
```

## Implementation Workflow

### Phase 1: Planning
```markdown
1. Identify target user and their pain points
2. Define core features (MVP)
3. Sketch UI layout
4. Identify integration points with existing systems
5. Get user approval on design
```

### Phase 2: Core Implementation
```markdown
1. Create plugin structure (if new plugin)
2. Implement data layer (reading game data)
3. Build Slate UI framework
4. Add core functionality
5. Integrate with game systems
```

### Phase 3: Polish
```markdown
1. Add error handling
2. Implement undo/redo where applicable
3. Add tooltips and documentation
4. Performance optimization
5. User testing and feedback
```

### Phase 4: Integration
```markdown
1. Register menu entries
2. Add keyboard shortcuts
3. Create documentation
4. Update plugin changelog
```

## Common Tool Patterns

### Details Panel Customization
```cpp
// Custom details for specific class
FPropertyEditorModule& PropertyModule = FModuleManager::LoadModuleChecked<FPropertyEditorModule>("PropertyEditor");
PropertyModule.RegisterCustomClassLayout(
    UMyDataAsset::StaticClass()->GetFName(),
    FOnGetDetailCustomizationInstance::CreateStatic(&FMyDataAssetDetails::MakeInstance)
);
```

### Asset Picker
```cpp
// Asset picker for selecting Data Assets
SNew(SObjectPropertyEntryBox)
    .ObjectPath(this, &SMyWidget::GetAssetPath)
    .OnObjectChanged(this, &SMyWidget::OnAssetChanged)
    .AllowedClass(UMyDataAsset::StaticClass())
    .DisplayBrowse(true)
    .DisplayThumbnail(true)
```

### World Outliner Integration
```cpp
// Get selected actors
TArray<AActor*> SelectedActors;
GEditor->GetSelectedActors()->GetSelectedObjects<AActor>(SelectedActors);
```

### Viewport Drawing
```cpp
// Debug draw in editor viewport
void FMyEditorMode::Render(const FSceneView* View, FViewport* Viewport, FPrimitiveDrawInterface* PDI)
{
    DrawDebugSphere(GetWorld(), Location, Radius, 32, FColor::Green, false, -1.0f, SDPG_World);
}
```

## Tool Ideas by User Type

### For Game Designers
| Tool | Purpose | Priority |
|------|---------|----------|
| Damage Curve Editor | Visual editing of damage falloff curves | High |
| Ability Cost Calculator | Preview resource costs for ability chains | High |
| Combat Feel Tuner | Adjust hitstop, screen shake, camera values | Medium |
| Difficulty Scaler | Preview enemy stats at different difficulties | Medium |

### For QA Combat Testers
| Tool | Purpose | Priority |
|------|---------|----------|
| Combat Log Viewer | Detailed combat event history | High |
| Hitbox Recorder | Record and replay hitbox states | High |
| Damage Verification | Compare actual vs expected damage | Medium |
| Frame Data Overlay | Show startup/active/recovery frames | Medium |

### For Enemy AI Content Makers
| Tool | Purpose | Priority |
|------|---------|----------|
| AI Template Creator | Create enemy from template | High |
| Behavior Tree Visualizer | See BT execution in real-time | High |
| Attack Pattern Editor | Define attack sequences visually | Medium |
| Spawn Volume Helper | Quick encounter area setup | Medium |

## Success Criteria

### Tool Completion Checklist
- [ ] Core functionality works
- [ ] Error handling comprehensive
- [ ] UI is intuitive and consistent
- [ ] Tooltips added for all controls
- [ ] Menu/toolbar integration complete
- [ ] Keyboard shortcuts defined
- [ ] Undo/redo support (where applicable)
- [ ] No memory leaks
- [ ] Documentation updated
- [ ] User acceptance testing passed

### Quality Standards
- Consistent with Epic's editor UI style
- Responsive (no blocking operations)
- Clear feedback for all actions
- Graceful error handling
- Accessible from multiple entry points

## Example Implementation Request

```
User: I need a tool for QA to quickly spawn enemies for combat testing

## Legacy Metadata

```yaml
skill: ue-editor-tools
invoke: /editor-tools:ue-editor-tools
type: implementation
category: editor-tools
scope: Plugins/Frameworks/
```
