---
name: huli-bp-tools
description: Implement and refactor UE5.7 editor tools with Technical Director oversight
---

# Unreal Engine 5.7 Editor Tool Implementation

**Role:** UE5 Editor Tools Engineer + Technical Director Reviewer
**Scope:** `Plugins/Marketplace/SipherAIBPTools/`
**Engine Version:** Unreal Engine 5.7.1
**Platform Focus:** Win64 Editor (Mac/Linux optional for WebBrowser support)
**Quality Standard:** Production-ready code for marketplace distribution

## Objective

Implement new features and refactor existing code in the SipherAIBPTools plugin, following Unreal Engine 5.7 best practices and Epic's coding standards. Every implementation undergoes Technical Director-level code review for quality assurance.

## Plugin Overview

**SipherAIBPTools** - AI-assisted Blueprint documentation and code generation tool

**Current Features:**
- 📊 Blueprint to Markdown/HTML documentation generation
- 🔍 Execution flow visualization with interactive HTML viewer
- 🌲 Behavior Tree documentation generation
- 💾 Auto-generation on Blueprint save
- 📝 Code review format output optimized for LLMs

**Future Roadmap:**
- 🤖 AI code to Blueprint node conversion
- 🔄 Reverse engineering: Import AI-generated pseudocode as Blueprint functions
- 🧠 Behavior Tree generation from AI descriptions
- 🎯 Enhanced semantic analysis for code quality insights

**Architecture:**
- **Extractors**: `BlueprintDataExtractor` - Parses UEdGraphNode data
- **Models**: `BlueprintNode`, `BlueprintPin` - Internal representation
- **Formatters**: `FMarkdownNodeFormatter` - Node-specific formatting logic
- **Tracers**: `MarkdownDataTracer`, `FMarkdownPathTracer` - Execution flow analysis
- **Generators**: `MarkdownDocumentBuilder`, `HTMLDocumentBuilder`, `BehaviorTreeDocumentBuilder`
- **Handlers**: 30+ specialized node handlers (Arrays, Delegates, Flow Control, etc.)
- **UI**: Slate-based output windows with WebBrowser integration

## UE5.7 Editor Tools Best Practices

### 1. Module Configuration

**✅ DO:**
```cpp
// Use explicit or shared PCHs
PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

// Minimize public dependencies (only expose what external modules need)
PublicDependencyModuleNames.AddRange(new string[] {
    "Core",
    "CoreUObject"
});

// Keep implementation details in private dependencies
PrivateDependencyModuleNames.AddRange(new string[] {
    "Engine", "UnrealEd", "BlueprintGraph", "Slate", "SlateCore"
});
```

**❌ DON'T:**
```cpp
// Don't expose internal dependencies as public
PublicDependencyModuleNames.Add("BlueprintGraph"); // Should be private

// Don't include editor modules in runtime builds (this is editor-only)
if (Target.Type == TargetType.Editor) // ✅ Already implied by "Editor" module type
```

### 2. Editor-Only Code Safety

**✅ DO:**
```cpp
// Module type is "Editor" in .uplugin - automatically editor-only
{
    "Name": "SipherAIBPTools",
    "Type": "Editor",  // ✅ Only loads in editor
    "LoadingPhase": "Default"
}

// Use WITH_EDITOR macros for additional safety
#if WITH_EDITOR
    void GenerateDocumentation();
#endif
```

**❌ DON'T:**
```cpp
// Don't ship editor tools in packaged builds
#if !UE_BUILD_SHIPPING  // ❌ WRONG - Use WITH_EDITOR instead
```

### 3. Slate UI Best Practices

**✅ DO:**
```cpp
// Use TSharedRef for owned widgets, TSharedPtr for optional
TSharedRef<SWidget> CreateMarkdownViewer()
{
    return SNew(SMarkdownOutputWindow)
        .MarkdownContent(this, &FSipherAIBPToolsModule::GetMarkdownContent)
        .OnCopyToClipboard(this, &FSipherAIBPToolsModule::HandleCopyToClipboard);
}

// Proper weak reference handling
TWeakPtr<SWindow> OutputWindowWeak;

void ShowWindow()
{
    if (TSharedPtr<SWindow> PinnedWindow = OutputWindowWeak.Pin())
    {
        // Window still exists, bring to front
        FSlateApplication::Get().AddWindow(PinnedWindow.ToSharedRef(), true);
    }
    else
    {
        // Create new window
        TSharedRef<SWindow> NewWindow = CreateOutputWindow();
        OutputWindowWeak = NewWindow;
        FSlateApplication::Get().AddWindow(NewWindow);
    }
}
```

**❌ DON'T:**
```cpp
// Don't use raw pointers for Slate widgets
SWindow* OutputWindow; // ❌ Memory leak risk

// Don't create multiple windows without tracking
void ShowWindow()
{
    // ❌ Creates new window every time, leaks previous ones
    FSlateApplication::Get().AddWindow(SNew(SWindow));
}
```

### 4. Asset Loading in Editor Tools

**✅ DO:**
```cpp
// Editor tools can use LoadObject (synchronous) - no console cert restrictions
UBlueprint* LoadBlueprintAsset(const FString& AssetPath)
{
    // ✅ ALLOWED in editor tools (not runtime)
    return LoadObject<UBlueprint>(nullptr, *AssetPath);
}

// But prefer AssetRegistry for searching
void FindAllBlueprints(TArray<FAssetData>& OutAssets)
{
    FAssetRegistryModule& AssetRegistry = FModuleManager::LoadModuleChecked<FAssetRegistryModule>("AssetRegistry");
    FARFilter Filter;
    Filter.ClassPaths.Add(UBlueprint::StaticClass()->GetClassPathName());
    AssetRegistry.Get().GetAssets(Filter, OutAssets);
}
```

**⚠️ IMPORTANT:**
- Editor tools CAN use `LoadSynchronous()` and `LoadObject()` (editor thread is not game thread)
- Runtime gameplay code (even in editor builds) CANNOT use synchronous loading
- SipherAIBPTools is Editor-only, so synchronous loading is acceptable here

### 5. Blueprint Graph Traversal

**✅ DO:**
```cpp
// Safely traverse Blueprint graphs
TArray<UEdGraphNode*> GetAllNodesFromBlueprint(UBlueprint* Blueprint)
{
    TArray<UEdGraphNode*> AllNodes;

    if (!IsValid(Blueprint))
    {
        UE_LOG(LogSipherAIBPTools, Error, TEXT("Invalid Blueprint"));
        return AllNodes;
    }

    // Iterate through all graphs (EventGraph, Functions, Macros, etc.)
    TArray<UEdGraph*> AllGraphs;
    Blueprint->GetAllGraphs(AllGraphs);

    for (UEdGraph* Graph : AllGraphs)
    {
        if (IsValid(Graph))
        {
            AllNodes.Append(Graph->Nodes);
        }
    }

    return AllNodes;
}

// Traverse execution flow correctly
void TraceExecutionPath(UEdGraphNode* StartNode, TArray<UEdGraphNode*>& OutPath)
{
    if (!StartNode) return;

    // Find "exec" output pin
    UEdGraphPin* ExecPin = nullptr;
    for (UEdGraphPin* Pin : StartNode->Pins)
    {
        if (Pin && Pin->PinType.PinCategory == UEdGraphSchema_K2::PC_Exec
            && Pin->Direction == EGPD_Output)
        {
            ExecPin = Pin;
            break;
        }
    }

    if (ExecPin && ExecPin->LinkedTo.Num() > 0)
    {
        UEdGraphNode* NextNode = ExecPin->LinkedTo[0]->GetOwningNode();
        if (NextNode && !OutPath.Contains(NextNode)) // Prevent cycles
        {
            OutPath.Add(NextNode);
            TraceExecutionPath(NextNode, OutPath); // Recursive
        }
    }
}
```

**❌ DON'T:**
```cpp
// Don't assume nodes/pins are valid
UEdGraphPin* Pin = Node->Pins[0]; // ❌ May be out of bounds
Pin->LinkedTo[0]->GetOwningNode(); // ❌ May be null

// Don't traverse without cycle detection
void TraverseGraph(UEdGraphNode* Node)
{
    for (UEdGraphPin* Pin : Node->Pins) // ❌ Infinite loop if graph has cycles
    {
        TraverseGraph(Pin->LinkedTo[0]->GetOwningNode());
    }
}
```

### 6. Logging and Diagnostics

**✅ DO:**
```cpp
// Use custom log category
DEFINE_LOG_CATEGORY_STATIC(LogSipherAIBPTools, Log, All);

// Log with context
UE_LOG(LogSipherAIBPTools, Warning,
    TEXT("Failed to extract nodes from graph '%s' in blueprint '%s'"),
    *GraphPath, *Blueprint->GetName());

// Categorize log levels correctly
UE_LOG(LogSipherAIBPTools, Error, TEXT("Critical failure"));   // Blocks functionality
UE_LOG(LogSipherAIBPTools, Warning, TEXT("Potential issue"));  // Degraded functionality
UE_LOG(LogSipherAIBPTools, Display, TEXT("Important info"));   // User-facing info
UE_LOG(LogSipherAIBPTools, Verbose, TEXT("Debug details"));    // Dev debugging
```

**❌ DON'T:**
```cpp
// Don't use LogTemp
UE_LOG(LogTemp, Warning, TEXT("Something happened")); // ❌ No searchability

// Don't log without context
UE_LOG(LogSipherAIBPTools, Error, TEXT("Failed")); // ❌ What failed? Where?
```

### 7. Command Registration (ToolMenus)

**✅ DO:**
```cpp
void FSipherAIBPToolsModule::RegisterMenus()
{
    // Register commands first
    FToolMenuOwnerScoped OwnerScoped(this);

    UToolMenu* Menu = UToolMenus::Get()->ExtendMenu("LevelEditor.MainMenu.Tools");
    FToolMenuSection& Section = Menu->AddSection("SipherAIBPTools",
        LOCTEXT("SipherAIBPToolsMenuSection", "Sipher AI BP Tools"));

    // Add menu entry with icon
    Section.AddMenuEntry(
        FSipherAIBPToolsCommands::Get().GenerateExecFlow,
        LOCTEXT("GenerateExecFlowLabel", "Generate Execution Flow"),
        LOCTEXT("GenerateExecFlowTooltip", "Generate markdown documentation from selected Blueprint nodes"),
        FSlateIcon(FSipherAIBPToolsStyle::GetStyleSetName(), "SipherAIBPTools.GenerateExecFlow")
    );
}
```

**⚠️ DEPRECATED:**
```cpp
// Don't use old menu extension API (UE4 style)
TSharedPtr<FExtender> MenuExtender = MakeShareable(new FExtender()); // ❌ Old API
MenuExtender->AddMenuExtension(...); // Use UToolMenus instead
```

### 8. Platform-Specific Code (WebBrowser)

**✅ DO:**
```cpp
// In .Build.cs - Conditional compilation
#if (Target.Platform == UnrealTargetPlatform.Win64 ||
     Target.Platform == UnrealTargetPlatform.Mac)
{
    PrivateDependencyModuleNames.Add("WebBrowser");
    PublicDefinitions.Add("WITH_WEBBROWSER=1");
}
#else
{
    PublicDefinitions.Add("WITH_WEBBROWSER=0");
}

// In code - Use the definition
#if WITH_WEBBROWSER
    TSharedRef<SWidget> CreateHTMLViewer()
    {
        return SNew(SWebBrowser)
            .InitialURL(TEXT("about:blank"))
            .ShowControls(false);
    }
#else
    TSharedRef<SWidget> CreateHTMLViewer()
    {
        return SNew(STextBlock)
            .Text(LOCTEXT("WebBrowserNotSupported", "HTML viewer not supported on this platform"));
    }
#endif
```

### 9. Memory Management

**✅ DO:**
```cpp
// Use TSharedPtr for non-UObject data
TSharedPtr<FBlueprintNode> NodeData = MakeShared<FBlueprintNode>();

// Use TMap with TSharedPtr values (automatic cleanup)
TMap<FString, TSharedPtr<FBlueprintNode>> NodeMap;

// UObjects managed by UE's GC
UPROPERTY()
TObjectPtr<UBlueprint> CachedBlueprint;

// Weak references to avoid GC issues
TWeakObjectPtr<UBlueprint> BlueprintWeak;
```

**❌ DON'T:**
```cpp
// Don't use raw new/delete for UObjects
UBlueprint* BP = new UBlueprint(); // ❌ NEVER
delete BP; // ❌ NEVER

// Don't hold strong references to editor objects unnecessarily
UBlueprint* CachedBP; // ❌ Not UPROPERTY - will be garbage collected

// Don't mix ownership models
TSharedPtr<UBlueprint> BP; // ❌ UObjects use GC, not shared_ptr
```

### 10. UE5.7 Reflection API (Critical for Behavior Tree & Graph Traversal)

**✅ DO:**
```cpp
// CORRECT: Access struct properties using ContainerPtrToValuePtr
void AccessChildNodeFromBTCompositeChild(const FBTCompositeChild& ChildStruct)
{
    // Get the struct type
    UScriptStruct* StructType = FBTCompositeChild::StaticStruct();

    // Find the property by name
    FObjectProperty* ChildCompositeProp = FindFProperty<FObjectProperty>(StructType, TEXT("ChildComposite"));

    if (ChildCompositeProp)
    {
        // Step 1: Get pointer to the property VALUE using ContainerPtrToValuePtr
        void* PropertyValuePtr = ChildCompositeProp->ContainerPtrToValuePtr<void>(&ChildStruct);

        // Step 2: Get the object from the property value pointer
        UObject* ObjectValue = ChildCompositeProp->GetObjectPropertyValue(PropertyValuePtr);

        // Step 3: Cast to the expected type
        UBTNode* ChildNode = Cast<UBTNode>(ObjectValue);

        if (ChildNode)
        {
            UE_LOG(LogSipherAIBPTools, Log, TEXT("Found child node: %s"), *ChildNode->GetName());
        }
    }
}

// Accessing array elements using FScriptArrayHelper
void ProcessBTCompositeChildren(UBTCompositeNode* CompositeNode)
{
    // Find the Children array property
    FArrayProperty* ChildrenProp = FindFProperty<FArrayProperty>(CompositeNode->GetClass(), TEXT("Children"));

    if (!ChildrenProp)
    {
        UE_LOG(LogSipherAIBPTools, Error, TEXT("Could not find Children property"));
        return;
    }

    // Get pointer to the array container
    void* ContainerPtr = ChildrenProp->ContainerPtrToValuePtr<void>(CompositeNode);

    // Create array helper to access elements
    FScriptArrayHelper ArrayHelper(ChildrenProp, ContainerPtr);

    // Iterate through array elements
    for (int32 i = 0; i < ArrayHelper.Num(); ++i)
    {
        // Get raw pointer to the struct element
        uint8* StructElementPtr = ArrayHelper.GetRawPtr(i);

        // Get the struct property (inner type of the array)
        FStructProperty* StructProp = CastField<FStructProperty>(ChildrenProp->Inner);

        if (StructProp && StructProp->Struct)
        {
            // Now access properties within the struct element
            FObjectProperty* ChildTaskProp = FindFProperty<FObjectProperty>(StructProp->Struct, TEXT("ChildTask"));

            if (ChildTaskProp)
            {
                // Use ContainerPtrToValuePtr with the struct element pointer
                void* PropertyValuePtr = ChildTaskProp->ContainerPtrToValuePtr<void>(StructElementPtr);
                UObject* TaskObject = ChildTaskProp->GetObjectPropertyValue(PropertyValuePtr);
                UBTTaskNode* TaskNode = Cast<UBTTaskNode>(TaskObject);

                if (TaskNode)
                {
                    UE_LOG(LogSipherAIBPTools, Log, TEXT("Found task: %s"), *TaskNode->GetName());
                }
            }
        }
    }
}

// Enumerating all properties in a struct for debugging
void DebugStructProperties(UScriptStruct* StructType)
{
    UE_LOG(LogSipherAIBPTools, Log, TEXT("Properties in struct '%s':"), *StructType->GetName());

    for (TFieldIterator<FProperty> PropIt(StructType); PropIt; ++PropIt)
    {
        FProperty* Prop = *PropIt;
        UE_LOG(LogSipherAIBPTools, Log, TEXT("  - %s (Type: %s)"),
            *Prop->GetName(),
            *Prop->GetClass()->GetName());
    }
}
```

**❌ DON'T:**
```cpp
// WRONG: Passing struct pointer directly to GetObjectPropertyValue
FObjectProperty* ChildNodeProp = FindFProperty<FObjectProperty>(StructType, TEXT("ChildNode"));
if (ChildNodeProp)
{
    // ❌ This will return nullptr - missing ContainerPtrToValuePtr step!
    UObject* ObjectValue = ChildNodeProp->GetObjectPropertyValue(&ChildStruct);
}

// WRONG: Assuming property names without checking
FObjectProperty* Prop = FindFProperty<FObjectProperty>(StructType, TEXT("ChildNode"));
// ❌ FBTCompositeChild has "ChildComposite" and "ChildTask", not "ChildNode"!

// WRONG: Not checking if property exists
void* ValuePtr = ChildNodeProp->ContainerPtrToValuePtr<void>(&ChildStruct);
// ❌ ChildNodeProp could be nullptr if FindFProperty failed!

// WRONG: Using GetObjectPropertyValue without proper pointer
UObject* Obj = Property->GetObjectPropertyValue(StructPtr);
// ❌ Need to call ContainerPtrToValuePtr first!
```

**🔍 Key Insights from Behavior Tree Documentation Implementation:**
1. **Property Access Pattern**: Always use `ContainerPtrToValuePtr()` before `GetObjectPropertyValue()`
2. **Struct vs Object Properties**: Structs in arrays require `FScriptArrayHelper` to access elements
3. **Property Naming**: Use `TFieldIterator` to discover actual property names - don't assume!
4. **Two-Step Process**:
   - Step 1: `ContainerPtrToValuePtr()` - Get pointer to where the value is stored
   - Step 2: `GetObjectPropertyValue()` - Read the value from that pointer
5. **FBTCompositeChild Specific**: Has `ChildComposite` (UBTCompositeNode*) and `ChildTask` (UBTTaskNode*), not a single `ChildNode` property

### 11. StateTree Reflection & Instance Data Access (Critical for AI Documentation)

**🔍 Key Architectural Insight:**
StateTree separates **task/condition logic** (stored in node structs) from **runtime configuration** (stored in instance data). When extracting properties via reflection, you MUST access BOTH:

```
┌─────────────────────────────────────────────────────────┐
│ Task Node Struct (e.g., FSipherStateTreeBehaviorTreeTask)│
│  - InstanceTemplateIndex → points to Instance Data       │
│  - bTaskEnabled, Name (generic properties)               │
│  - Does NOT contain BehaviorTree reference!              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ Instance Data (FSipherStateTreeBehaviorTreeInstanceData) │
│  - BehaviorTree: TObjectPtr<UBehaviorTree>  ← HERE!      │
│  - Goals, Tags, Montages, etc.                           │
│  - All user-configured values live here                  │
└─────────────────────────────────────────────────────────┘
```

**✅ DO - Access Both Node Struct AND Instance Data:**
```cpp
#include "StateTreeNodeBase.h"
#include "StateTreeInstanceData.h"

void ExtractTaskProperties(UStateTree* StateTree, int32 NodeIndex)
{
    // Step 1: Get the task node struct
    FConstStructView NodeView = StateTree->GetNode(NodeIndex);
    const UScriptStruct* NodeStruct = NodeView.GetScriptStruct();
    const uint8* NodeMemory = NodeView.GetMemory();

    // Extract properties from task struct (generic properties like bTaskEnabled)
    TArray<TPair<FString, FString>> Properties = ExtractNodeProperties(NodeView);

    // Step 2: Get Instance Data (where BehaviorTree, Goals, Tags are stored!)
    if (NodeStruct && NodeMemory)
    {
        // Find InstanceTemplateIndex property from FStateTreeNodeBase
        const FProperty* IndexProp = NodeStruct->FindPropertyByName(TEXT("InstanceTemplateIndex"));
        if (IndexProp)
        {
            // Get the index value
            const FStateTreeIndex16* TemplateIndex =
                IndexProp->ContainerPtrToValuePtr<FStateTreeIndex16>(NodeMemory);

            if (TemplateIndex && TemplateIndex->IsValid())
            {
                // Access the default instance data storage
                const FStateTreeInstanceData& DefaultInstanceData =
                    StateTree->GetDefaultInstanceData();
                int32 Index = static_cast<int32>(TemplateIndex->Get());

                if (DefaultInstanceData.IsValidIndex(Index))
                {
                    // Get the instance data struct
                    FConstStructView InstanceDataView = DefaultInstanceData.GetStruct(Index);

                    if (InstanceDataView.IsValid())
                    {
                        // Extract properties from instance data
                        // This is where BehaviorTree, Goals, Tags are!
                        TArray<TPair<FString, FString>> InstanceProps =
                            ExtractNodeProperties(InstanceDataView);

                        // Merge: instance data takes precedence
                        for (const auto& InstProp : InstanceProps)
                        {
                            // Add or override with instance data values
                            Properties.Add(InstProp);
                        }
                    }
                }
            }
        }
    }
}
```

**❌ DON'T - Only Extract from Node Struct:**
```cpp
// WRONG: This will NOT find BehaviorTree!
void ExtractTaskProperties_WRONG(UStateTree* StateTree, int32 NodeIndex)
{
    FConstStructView NodeView = StateTree->GetNode(NodeIndex);

    // ❌ This only gets properties from the task struct
    // BehaviorTree is in Instance Data, not here!
    TArray<TPair<FString, FString>> Properties = ExtractNodeProperties(NodeView);

    // Will NOT contain: BehaviorTree, Goals, Tags, etc.
}
```

**🔍 Key StateTree Classes:**

| Class | Purpose | Contains |
|-------|---------|----------|
| `UStateTree` | The StateTree asset | `GetNodes()`, `GetStates()`, `GetDefaultInstanceData()` |
| `FCompactStateTreeState` | State definition | TasksBegin, TasksNum, ConditionsBegin, etc. |
| `FStateTreeNodeBase` | Base for tasks/conditions | `InstanceTemplateIndex` → points to instance data |
| `FStateTreeInstanceData` | Runtime config storage | `GetStruct(Index)` → returns instance data |
| `FStateTreeIndex16` | Index wrapper | `IsValid()`, `Get()` |

**🔍 Common Instance Data Structs:**

| Task Type | Instance Data Struct | Key Properties |
|-----------|---------------------|----------------|
| BehaviorTreeTask | `FSipherStateTreeBehaviorTreeInstanceData` | `BehaviorTree`, `bBTSingleExecution` |
| HasGoalCondition | `FStateHasGoalConditionInstanceData` | `Goals` (FGameplayTagContainer) |
| GameplayTagMatch | `FGameplayTagMatchConditionInstanceData` | `Tag` (FGameplayTag) |
| PlayMontage | `FStateTreePlayMontageInstanceData` | `Montage`, `PlayRate` |

**⚠️ IMPORTANT:**
- `GetDefaultInstanceData()` returns the **editor-time configured values**
- Runtime values may differ (bindings, parameters)
- For documentation generation, default instance data is what you want
- Always check `IsValidIndex()` before accessing storage
- Use `TFieldIterator<FProperty>` with `EFieldIteratorFlags::IncludeSuper` to get inherited properties

### 12. Commandlet Support

**✅ DO:**
```cpp
// Commandlet for batch processing
UCLASS()
class USipherAIBPToolsCommandlet : public UCommandlet
{
    GENERATED_BODY()

public:
    USipherAIBPToolsCommandlet();

    virtual int32 Main(const FString& Params) override;
};

// Usage: UnrealEditor.exe ProjectName -run=SipherAIBPTools -blueprints=/Game/MyBlueprints
int32 USipherAIBPToolsCommandlet::Main(const FString& Params)
{
    UE_LOG(LogSipherAIBPTools, Display, TEXT("Running SipherAIBPTools commandlet"));

    // Parse parameters
    FString BlueprintPath;
    if (!FParse::Value(*Params, TEXT("-blueprints="), BlueprintPath))
    {
        UE_LOG(LogSipherAIBPTools, Error, TEXT("Missing -blueprints parameter"));
        return 1; // Error
    }

    // Process blueprints...
    return 0; // Success
}
```

## Implementation Workflow

### Phase 1: Planning & Design (Use EnterPlanMode)
1. **Understand Requirements**
   - Read user request carefully
   - Identify affected systems (Extractors, Formatters, Tracers, etc.)
   - Check for similar existing functionality

2. **Explore Current Code**
   - Use Read/Grep to understand existing patterns
   - Identify reusable components
   - Note areas requiring refactoring

3. **Design Solution**
   - Follow plugin architecture (Extractor → Model → Formatter → Generator)
   - Use Technical Director knowledge for scalability assessment
   - Consider edge cases (empty graphs, circular references, malformed Blueprints)

4. **Get User Approval**
   - Use AskUserQuestion for design choices
   - Present architectural trade-offs
   - Exit plan mode with clear implementation plan

### Phase 2: Implementation
1. **Create Todo List**
   ```markdown
   Using TodoWrite:
   - [ ] Implement core feature logic
   - [ ] Add unit tests (if applicable)
   - [ ] Update UI integration
   - [ ] Add logging and diagnostics
   - [ ] Update documentation
   ```

2. **Implement Feature**
   - Follow UE5.7 coding standards (see checklist below)
   - Add comprehensive logging
   - Handle edge cases gracefully
   - Use existing plugin patterns

3. **Self-Review**
   - Check against coding standards checklist
   - Verify no console cert violations (even though editor-only)
   - Ensure proper memory management

### Phase 3: Technical Director Review
1. **Launch Technical Director Agent**
   ```markdown
   Use Task tool with subagent_type='technical-director':
   - Review implementation for UE5.7 best practices
   - Identify performance bottlenecks
   - Check architectural consistency
   - Verify Epic coding standards compliance
   ```

2. **Address Feedback**
   - Implement suggested improvements
   - Refactor as needed
   - Re-review if major changes made

3. **Generate Report**
   - Save to `claude-agents/reports/technical-director/ue-tools/[feature_name]_review.md`
   - Include code quality grade
   - Document any tech debt added

## Coding Standards Checklist

### UE5 Coding Standards
- [ ] Use `nullptr` instead of `NULL`
- [ ] Use `TObjectPtr<T>` for UPROPERTY UObject references (UE5.1+)
- [ ] Use `TArray`, `TMap`, `TSet` (not STL containers)
- [ ] Use `FString`, `FName`, `FText` correctly
  - `FString`: Mutable, general-purpose strings
  - `FName`: Immutable, case-insensitive identifiers (assets, properties)
  - `FText`: Localized, display strings (UI)
- [ ] Prefix class names: `U` (UObject), `A` (AActor), `F` (POD struct), `S` (Slate), `I` (Interface)
- [ ] Use `UPROPERTY()` for all UObject/AActor member variables
- [ ] Use `UFUNCTION()` for Blueprint-exposed or RPC functions
- [ ] Use `USTRUCT()` for Blueprint-exposed structs

### Plugin-Specific Patterns
- [ ] Follow existing architecture: Extractor → Model → Formatter → Generator
- [ ] Add new node handlers to `Trace/Handlers/` if needed
- [ ] Use `LogSipherAIBPTools` for all logging
- [ ] Update `FSipherAIBPToolsCommands` for new menu entries
- [ ] Add UI to `SMarkdownOutputWindow` or create new Slate widget
- [ ] Support commandlet batch processing when applicable

### Performance
- [ ] Cache UObject lookups (AssetRegistry results, Blueprint references)
- [ ] Avoid O(n²) graph traversals (use TSet for visited nodes)
- [ ] Lazy-load large data structures
- [ ] Profile with Unreal Insights if processing > 100 Blueprints

### Error Handling
- [ ] Validate all UObject pointers with `IsValid()`
- [ ] Check array bounds before indexing
- [ ] Handle missing/corrupted Blueprint assets gracefully
- [ ] Log errors with full context (asset path, node name, operation)

### Documentation
- [ ] Add Doxygen comments for public API
- [ ] Update plugin description in `.uplugin` if adding major features
- [ ] Document commandlet parameters in header comments
- [ ] Add usage examples for complex features

## Common Pitfalls

### 1. Blueprint Graph State Assumptions

**❌ WRONG:**
```cpp
// Assuming EventGraph exists and has nodes
UEdGraph* EventGraph = Blueprint->UbergraphPages[0];
UEdGraphNode* FirstNode = EventGraph->Nodes[0]; // May be empty!
```

**✅ CORRECT:**
```cpp
UEdGraph* EventGraph = nullptr;
if (Blueprint->UbergraphPages.Num() > 0)
{
    EventGraph = Blueprint->UbergraphPages[0];
}

if (EventGraph && EventGraph->Nodes.Num() > 0)
{
    UEdGraphNode* FirstNode = EventGraph->Nodes[0];
    // Process node...
}
else
{
    UE_LOG(LogSipherAIBPTools, Warning,
        TEXT("Blueprint '%s' has no nodes in EventGraph"),
        *Blueprint->GetName());
}
```

### 2. Pin Type Assumptions

**❌ WRONG:**
```cpp
// Assuming pin is exec pin
if (Pin->LinkedTo.Num() > 0)
{
    TraceExecution(Pin->LinkedTo[0]->GetOwningNode());
}
```

**✅ CORRECT:**
```cpp
if (Pin->PinType.PinCategory == UEdGraphSchema_K2::PC_Exec &&
    Pin->Direction == EGPD_Output &&
    Pin->LinkedTo.Num() > 0)
{
    UEdGraphNode* NextNode = Pin->LinkedTo[0]->GetOwningNode();
    if (IsValid(NextNode))
    {
        TraceExecution(NextNode);
    }
}
```

### 3. Circular Reference Detection

**❌ WRONG:**
```cpp
void TraverseNodes(UEdGraphNode* Node)
{
    // Infinite loop on circular graphs!
    for (UEdGraphPin* Pin : Node->Pins)
    {
        if (Pin->LinkedTo.Num() > 0)
        {
            TraverseNodes(Pin->LinkedTo[0]->GetOwningNode());
        }
    }
}
```

**✅ CORRECT:**
```cpp
void TraverseNodes(UEdGraphNode* Node, TSet<UEdGraphNode*>& VisitedNodes)
{
    if (!Node || VisitedNodes.Contains(Node))
        return; // Already visited

    VisitedNodes.Add(Node);

    for (UEdGraphPin* Pin : Node->Pins)
    {
        if (Pin && Pin->LinkedTo.Num() > 0)
        {
            UEdGraphNode* NextNode = Pin->LinkedTo[0]->GetOwningNode();
            if (IsValid(NextNode))
            {
                TraverseNodes(NextNode, VisitedNodes);
            }
        }
    }
}
```

### 4. FString Abuse

**❌ WRONG:**
```cpp
FString AssetPath = "/Game/Blueprints/MyBP";
if (AssetPath == "/Game/Blueprints/MyBP") // Expensive string comparison
{
    // Use FName for identifiers
}

// Building strings in loop
FString Output;
for (int32 i = 0; i < 1000; ++i)
{
    Output += FString::Printf(TEXT("Line %d\n"), i); // Reallocates every iteration
}
```

**✅ CORRECT:**
```cpp
FName AssetPath = "/Game/Blueprints/MyBP";
if (AssetPath == "/Game/Blueprints/MyBP") // Fast hash comparison
{
    // Process...
}

// Use StringBuilder for concatenation
TStringBuilder<1024> OutputBuilder;
for (int32 i = 0; i < 1000; ++i)
{
    OutputBuilder.Appendf(TEXT("Line %d\n"), i);
}
FString Output = OutputBuilder.ToString();
```

## Testing Strategy

### Manual Testing Checklist
- [ ] Test with empty Blueprint (no nodes)
- [ ] Test with Blueprint containing only comment boxes
- [ ] Test with circular execution paths (loops)
- [ ] Test with deeply nested function calls (10+ levels)
- [ ] Test with malformed Blueprint (missing connections)
- [ ] Test with large Blueprint (1000+ nodes)
- [ ] Test with Behavior Tree (if BT feature)
- [ ] Test auto-generation on save feature
- [ ] Test commandlet batch processing

### Unreal Editor Workflow Test
1. **In-Editor Testing:**
   - Tools → Sipher AI BP Tools → [Your Feature]
   - Verify UI appears correctly
   - Verify output matches expectations
   - Check Output Log for warnings/errors

2. **Commandlet Testing:**
   ```bash
   UnrealEditor.exe S2.uproject -run=SipherAIBPTools -blueprints=/Game/MyBP
   ```

3. **Regression Testing:**
   - Verify existing features still work (Exec Flow, Behavior Tree)
   - Check auto-generation didn't break
   - Verify output format consistency

## Output Format

### Feature Implementation Report
Generate report in: `claude-agents/reports/ue-tools/[feature_name]_implementation.md`

```markdown
# [Feature Name] - Implementation Report

**Date:** YYYY-MM-DD
**Engineer:** AI Agent
**Reviewer:** Technical Director AI Agent
**Files Modified:** [List]
**Lines Changed:** +XXX -YYY

## 📊 Executive Summary

**Implementation Status:** ✅ Complete | ⏳ In Progress | 🔴 Blocked
**Code Quality Grade:** [A-F]
**Test Coverage:** Manual only (no automated tests)

## 🎯 Feature Description

[Clear description of what was implemented]

## 📁 Files Changed

### New Files
- `Path/To/NewFile.h` - [Purpose]
- `Path/To/NewFile.cpp` - [Implementation]

### Modified Files
- `Path/To/ExistingFile.cpp:123` - [What changed]

## 🔧 Implementation Details

### Architecture
[Describe how feature fits into plugin architecture]

### Key Design Decisions
1. **Decision**: [What you chose]
   - **Rationale**: [Why]
   - **Trade-offs**: [Alternatives considered]

## ✅ Technical Director Review

[Include TD agent review summary]

### Code Quality Assessment
🔴 **Critical Issues**: 0 | 🟡 **High Priority**: 0 | 🟢 **Medium**: 0

### Recommendations Implemented
- ✅ [Recommendation 1]
- ✅ [Recommendation 2]

## 🧪 Testing Performed

- [x] Empty Blueprint
- [x] Large Blueprint (1000+ nodes)
- [x] Circular execution paths
- [x] Commandlet batch processing
- [x] Auto-generation on save

## 📚 Documentation Updates

- Updated `SipherAIBPTools.uplugin` description
- Added Doxygen comments to public API
- Documented commandlet parameters

## 🚀 Next Steps

- [ ] User acceptance testing
- [ ] Performance profiling with Insights (if processing > 100 BPs)
- [ ] Consider automated test integration (Gauntlet/Automation framework)

---

**Implementation Complete:** [Timestamp]
```

## Example Invocation

**Implementing New Feature:**
```
/skill implement-ue-tool

I need to add a new feature to SipherAIBPTools: Export Blueprint graph as Mermaid diagram format.

Requirements:
- Parse Blueprint execution flow (like current Exec Flow feature)
- Generate Mermaid.js syntax instead of Markdown
- Support both flowchart and sequence diagram formats
- Add toolbar button to Blueprint editor
- Include in auto-generation options
```

**Refactoring Existing Code:**
```
/skill implement-ue-tool

Please refactor the BlueprintDataExtractor class:
- The ExtractFromSelectedNodes method is 300+ lines
- Needs better separation of concerns
- Add unit tests if possible
- Improve error handling for corrupted Blueprints
- Follow Technical Director's recommendations from previous review
```

**Adding Platform Support:**
```
/skill implement-ue-tool

Extend WebBrowser support to Linux platform:
- Currently only Win64/Mac supported
- Add Linux conditional compilation
- Test HTML viewer on Linux
- Update .Build.cs accordingly
```

## Knowledge Base References

- **Plugin Architecture**: `Plugins/Marketplace/SipherAIBPTools/Source/SipherAIBPTools/`
- **UE5 Editor Docs**: Epic's official Editor Scripting documentation
- **Technical Director Reports**: `claude-agents/reports/technical-director/ue-tools/`
- **Project Standards**: `/CLAUDE.md` - General UE5.7 standards

## Success Criteria

**Implementation Complete When:**
- ✅ Feature works in Unreal Editor
- ✅ All files compile without warnings
- ✅ Manual testing checklist passed
- ✅ Technical Director review complete (Grade B+ or higher)
- ✅ Logging added with proper categories
- ✅ Error handling comprehensive
- ✅ Documentation updated (code comments + report)
- ✅ No memory leaks detected
- ✅ Follows plugin architecture patterns
- ✅ Backward compatible with existing features

**Code Quality Standards:**
- No `LogTemp` usage
- All UObject pointers validated
- Proper TSharedPtr/TObjectPtr usage
- Circular reference detection in graph traversal
- Graceful handling of edge cases
- Comprehensive Doxygen comments on public API

## Legacy Metadata

```yaml
skill: huli-bp-tools
invoke: /editor-tools:huli-bp-tools
type: implementation
category: ue-tools-development
scope: Plugins/Marketplace/SipherAIBPTools
```
