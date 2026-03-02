---
name: ue-tag-filter-system
description: Implement a reusable tagging, filtering, and status tracking system for UE5 editor tools. Use when building editor tools that need categorization (type tags), status tracking (WIP/Playtest/Production), filter UI with colored accent strips, bulk tagging on groups, and JSON persistence shared via version control. Based on SipherAbilityWiki montage tagging pattern.
---

# UE5 Tag Filter System

**Purpose:** Add categorization, status tracking, and filtering to any editor tool with shared persistence via Git.

**Reference Implementation:** `Plugins/EditorTools/SipherAbilityWiki/` (montage tagging system)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer (Slate)                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Filter Bar  │  │ List/Tree   │  │ Detail Panel        │  │
│  │ (Tag Btns)  │  │ (Accents)   │  │ (Tag Editor)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Subsystem Layer (UEditorSubsystem)                         │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Tag Management: Get/Set tags, Query with filters        ││
│  │ Persistence: Load/Save JSON, Version control friendly   ││
│  └─────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Config/ToolName/tags.json)                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ { "ItemPath": { "TypeTag": "Melee", "StatusTag": "WIP" }}│
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Tag Enums (AbilityWikiTypes.h pattern)

```cpp
// Type classification tags (customize per tool)
UENUM()
enum class EItemTypeTag : uint8
{
    None        UMETA(DisplayName = "None"),
    Category1   UMETA(DisplayName = "Category 1"),
    Category2   UMETA(DisplayName = "Category 2"),
    // Add domain-specific categories
};

// Status/readiness tags (universal)
UENUM()
enum class EItemStatusTag : uint8
{
    None            UMETA(DisplayName = "None"),
    WIP             UMETA(DisplayName = "WIP"),
    Playtest        UMETA(DisplayName = "Playtest"),
    InProduction    UMETA(DisplayName = "In Production")
};
```

### 2. Tag Data Structs

```cpp
USTRUCT()
struct FItemTagData
{
    GENERATED_BODY()

    UPROPERTY()
    EItemTypeTag TypeTag = EItemTypeTag::None;

    UPROPERTY()
    EItemStatusTag StatusTag = EItemStatusTag::None;

    bool HasAnyTag() const
    {
        return TypeTag != EItemTypeTag::None || StatusTag != EItemStatusTag::None;
    }
};

USTRUCT()
struct FTagDatabase
{
    GENERATED_BODY()

    UPROPERTY()
    TMap<FString, FItemTagData> ItemTags;  // ItemPath -> TagData

    UPROPERTY()
    int32 Version = 1;
};
```

### 3. Color Helpers

```cpp
namespace TagHelpers
{
    inline FLinearColor GetTypeTagColor(EItemTypeTag Tag)
    {
        switch (Tag)
        {
        case EItemTypeTag::Category1: return FLinearColor(0.9f, 0.3f, 0.3f, 1.0f);  // Red
        case EItemTypeTag::Category2: return FLinearColor(0.3f, 0.7f, 0.9f, 1.0f);  // Blue
        default: return FLinearColor(0.5f, 0.5f, 0.5f, 1.0f);  // Gray
        }
    }

    inline FLinearColor GetStatusTagColor(EItemStatusTag Tag)
    {
        switch (Tag)
        {
        case EItemStatusTag::WIP:          return FLinearColor(0.9f, 0.5f, 0.2f, 1.0f);  // Orange
        case EItemStatusTag::Playtest:     return FLinearColor(0.9f, 0.9f, 0.2f, 1.0f);  // Yellow
        case EItemStatusTag::InProduction: return FLinearColor(0.2f, 0.8f, 0.3f, 1.0f);  // Green
        default: return FLinearColor(0.5f, 0.5f, 0.5f, 1.0f);  // Gray
        }
    }
}
```

## Subsystem Pattern

### Tag Storage (Config folder for Git sharing)

```cpp
FString UMyToolSubsystem::GetTagDatabasePath() const
{
    // Config folder is version controlled, Saved is gitignored
    return FPaths::ProjectConfigDir() / TEXT("MyTool") / TEXT("tags.json");
}

void UMyToolSubsystem::LoadTagDatabaseFromDisk()
{
    FString TagPath = GetTagDatabasePath();

    // Migration from old Saved location (one-time)
    FString OldPath = FPaths::ProjectSavedDir() / TEXT("MyTool") / TEXT("tags.json");
    if (!FPaths::FileExists(TagPath) && FPaths::FileExists(OldPath))
    {
        IFileManager::Get().MakeDirectory(*FPaths::GetPath(TagPath), true);
        IFileManager::Get().Copy(*TagPath, *OldPath);
    }

    if (FPaths::FileExists(TagPath))
    {
        FString JsonString;
        if (FFileHelper::LoadFileToString(JsonString, *TagPath))
        {
            FJsonObjectConverter::JsonObjectStringToUStruct(JsonString, &TagDatabase);
        }
    }
}

void UMyToolSubsystem::SaveTagDatabaseToDisk()
{
    FString TagPath = GetTagDatabasePath();
    IFileManager::Get().MakeDirectory(*FPaths::GetPath(TagPath), true);

    FString JsonString;
    FJsonObjectConverter::UStructToJsonObjectString(TagDatabase, JsonString);
    FFileHelper::SaveStringToFile(JsonString, *TagPath);
}
```

### Query API

```cpp
FItemTagData UMyToolSubsystem::GetItemTagData(const FString& ItemPath) const
{
    if (const FItemTagData* Found = TagDatabase.ItemTags.Find(ItemPath))
    {
        return *Found;
    }
    return FItemTagData();
}

void UMyToolSubsystem::SetItemTypeTag(const FString& ItemPath, EItemTypeTag NewTag)
{
    TagDatabase.ItemTags.FindOrAdd(ItemPath).TypeTag = NewTag;
    SaveTagDatabaseToDisk();
}

void UMyToolSubsystem::SetItemStatusTag(const FString& ItemPath, EItemStatusTag NewTag)
{
    TagDatabase.ItemTags.FindOrAdd(ItemPath).StatusTag = NewTag;
    SaveTagDatabaseToDisk();
}

TArray<FMyItemEntry> UMyToolSubsystem::SearchItemsWithTags(
    const FString& Query,
    EItemTypeTag TypeFilter,
    EItemStatusTag StatusFilter) const
{
    TArray<FMyItemEntry> Results;
    for (const FMyItemEntry& Item : AllItems)
    {
        // Apply text filter
        if (!Query.IsEmpty() && !Item.DisplayName.Contains(Query))
            continue;

        // Apply tag filters
        FItemTagData Tags = GetItemTagData(Item.Path);
        if (TypeFilter != EItemTypeTag::None && Tags.TypeTag != TypeFilter)
            continue;
        if (StatusFilter != EItemStatusTag::None && Tags.StatusTag != StatusFilter)
            continue;

        Results.Add(Item);
    }
    return Results;
}
```

## UI Patterns

### Filter Button with Accent Strip

**Key:** Use `SBorder` with `BorderBackgroundColor_Lambda`, NOT `ButtonColorAndOpacity`.

```cpp
auto MakeFilterButton = [this](EItemTypeTag Tag, const FText& Label) -> TSharedRef<SWidget>
{
    FLinearColor TagColor = TagHelpers::GetTypeTagColor(Tag);
    FLinearColor DimColor = FLinearColor(TagColor.R * 0.4f, TagColor.G * 0.4f, TagColor.B * 0.4f, 1.0f);

    return SNew(SBorder)
        .BorderImage(FAppStyle::GetBrush("ToolPanel.GroupBorder"))
        .BorderBackgroundColor_Lambda([this, Tag]() {
            bool bActive = (CurrentTypeFilter == Tag);
            return bActive ? FLinearColor(0.15f, 0.15f, 0.15f) : FLinearColor(0.08f, 0.08f, 0.08f);
        })
        .Padding(0)
        [
            SNew(SButton)
            .ButtonStyle(FAppStyle::Get(), "SimpleButton")
            .ContentPadding(FMargin(8, 4))
            .OnClicked_Lambda([this, Tag]() {
                CurrentTypeFilter = (CurrentTypeFilter == Tag) ? EItemTypeTag::None : Tag;
                RefreshList();
                return FReply::Handled();
            })
            [
                SNew(SVerticalBox)
                + SVerticalBox::Slot().AutoHeight().HAlign(HAlign_Center)
                [
                    SNew(STextBlock)
                    .Text(Label)
                    .Font(FAppStyle::GetFontStyle("SmallFont"))
                    .ColorAndOpacity_Lambda([this, Tag]() {
                        return (CurrentTypeFilter == Tag)
                            ? FSlateColor(FLinearColor::White)
                            : FSlateColor(FLinearColor(0.6f, 0.6f, 0.6f));
                    })
                ]
                // Accent strip at bottom
                + SVerticalBox::Slot().AutoHeight().Padding(0, 3, 0, 0)
                [
                    SNew(SBox).HeightOverride_Lambda([this, Tag]() {
                        return (CurrentTypeFilter == Tag) ? 3.0f : 2.0f;
                    })
                    [
                        SNew(SBorder)
                        .BorderImage(FAppStyle::GetBrush("WhiteBrush"))
                        .BorderBackgroundColor_Lambda([this, Tag, TagColor, DimColor]() {
                            return (CurrentTypeFilter == Tag) ? TagColor : DimColor;
                        })
                    ]
                ]
            ]
        ];
};
```

### Row Accent Strips (Two Columns)

```cpp
// In OnGenerateRow:
FItemTagData TagData = Subsystem->GetItemTagData(Item->Path);

FLinearColor TypeColor = TagData.TypeTag != EItemTypeTag::None
    ? TagHelpers::GetTypeTagColor(TagData.TypeTag)
    : FLinearColor(0.15f, 0.15f, 0.15f, 1.0f);
FLinearColor StatusColor = TagData.StatusTag != EItemStatusTag::None
    ? TagHelpers::GetStatusTagColor(TagData.StatusTag)
    : FLinearColor(0.15f, 0.15f, 0.15f, 1.0f);

return SNew(STableRow<...>, OwnerTable)
[
    SNew(SHorizontalBox)
    // Type tag accent (4px)
    + SHorizontalBox::Slot().AutoWidth().Padding(0)
    [
        SNew(SBox).WidthOverride(4)
        [
            SNew(SBorder)
            .BorderImage(FAppStyle::GetBrush("WhiteBrush"))
            .BorderBackgroundColor(TypeColor)
        ]
    ]
    // Status tag accent (4px)
    + SHorizontalBox::Slot().AutoWidth().Padding(0, 0, 4, 0)
    [
        SNew(SBox).WidthOverride(4)
        [
            SNew(SBorder)
            .BorderImage(FAppStyle::GetBrush("WhiteBrush"))
            .BorderBackgroundColor(StatusColor)
        ]
    ]
    // Rest of row content...
];
```

### Bulk Tagging on Groups

```cpp
void SMyPanel::ApplyTypeTagToGroup(TSharedPtr<FTreeItem> GroupItem, EItemTypeTag NewTag)
{
    if (!GroupItem.IsValid() || !GroupItem->bIsGroup) return;

    UMyToolSubsystem* Subsystem = GetSubsystem();
    if (!Subsystem) return;

    for (const TSharedPtr<FTreeItem>& Child : GroupItem->Children)
    {
        if (Child.IsValid() && !Child->bIsGroup)
        {
            Subsystem->SetItemTypeTag(Child->Data.Path, NewTag);
        }
    }

    // Refresh UI
    if (TreeView.IsValid()) TreeView->RebuildList();
}

TSharedRef<SWidget> SMyPanel::BuildGroupBulkTagButtons(TSharedPtr<FTreeItem> GroupItem)
{
    auto MakeTagBtn = [this, GroupItem](EItemTypeTag Tag, const FText& Label) {
        return SNew(SButton)
            .ButtonStyle(FAppStyle::Get(), "SimpleButton")
            .ContentPadding(FMargin(6, 2))
            .OnClicked_Lambda([this, GroupItem, Tag]() {
                ApplyTypeTagToGroup(GroupItem, Tag);
                return FReply::Handled();
            })
            [
                SNew(SVerticalBox)
                + SVerticalBox::Slot().AutoHeight().HAlign(HAlign_Center)
                [ SNew(STextBlock).Text(Label).Font(FAppStyle::GetFontStyle("SmallFont")) ]
                + SVerticalBox::Slot().AutoHeight().Padding(0, 2, 0, 0)
                [
                    SNew(SBox).HeightOverride(3)
                    [
                        SNew(SBorder)
                        .BorderImage(FAppStyle::GetBrush("WhiteBrush"))
                        .BorderBackgroundColor(TagHelpers::GetTypeTagColor(Tag))
                    ]
                ]
            ];
    };

    return SNew(SHorizontalBox)
        + SHorizontalBox::Slot().AutoWidth().Padding(1, 0)[ MakeTagBtn(EItemTypeTag::Category1, LOCTEXT("C1", "C1")) ]
        + SHorizontalBox::Slot().AutoWidth().Padding(1, 0)[ MakeTagBtn(EItemTypeTag::Category2, LOCTEXT("C2", "C2")) ];
}
```

### Storage Info Bar

```cpp
// Add below filter row to inform users about persistence
+ SVerticalBox::Slot().AutoHeight().Padding(4, 0, 4, 4)
[
    SNew(SHorizontalBox)
    + SHorizontalBox::Slot().AutoWidth().VAlign(VAlign_Center).Padding(0, 0, 4, 0)
    [
        SNew(SImage)
        .Image(FAppStyle::GetBrush("Icons.Info"))
        .ColorAndOpacity(FSlateColor(FLinearColor(0.4f, 0.6f, 0.8f, 0.8f)))
        .DesiredSizeOverride(FVector2D(12, 12))
    ]
    + SHorizontalBox::Slot().AutoWidth().VAlign(VAlign_Center)
    [
        SNew(STextBlock)
        .Text(LOCTEXT("TagStorageInfo", "Tags auto-saved to Config/MyTool/tags.json (shared via Git)"))
        .Font(FAppStyle::GetFontStyle("SmallFont"))
        .ColorAndOpacity(FSlateColor(FLinearColor(0.5f, 0.5f, 0.5f, 1.0f)))
    ]
]
```

## Implementation Checklist

1. **Define tag enums** - Type categories + Status tags
2. **Create tag data structs** - FItemTagData, FTagDatabase
3. **Add color helpers** - GetTypeTagColor, GetStatusTagColor
4. **Implement subsystem** - Load/Save JSON to Config folder
5. **Add filter buttons** - SBorder + accent strip pattern
6. **Add row accents** - Two 4px columns for type/status
7. **Add bulk tagging** - Apply tags to grouped items
8. **Add storage info** - Inform users about persistence location

## Key Gotchas

- **DO use `SBorder.BorderBackgroundColor_Lambda`** for dynamic backgrounds
- **DON'T use `SButton.ButtonColorAndOpacity`** - doesn't display properly
- **DO store in `Config/` folder** for version control
- **DON'T store in `Saved/` folder** - gitignored, not shared
- **DO add migration** from old Saved location if retrofitting
- **DO refresh UI** after tag changes (RebuildList)

## Related Skills

- `/editor-tools:create-editor-plugin` - Create plugin skeleton
- `/editor-tools:ue-editor-tools` - General editor tool patterns

## Legacy Metadata

```yaml
skill: ue-tag-filter-system
invoke: /editor-tools:ue-tag-filter-system
type: implementation
category: editor-tools
scope: Plugins/EditorTools/
```
