# Screenshot Naming Convention

Defines the order, prefix, and naming pattern for each screenshot type.

---

## Screenshot Sequence

| Order | Prefix | View Mode | Filename | Description |
|-------|--------|-----------|----------|-------------|
| 1 | 001 | Game_Epic | 001_Game_Epic.jpg | Game view at Epic quality |
| 2 | 002 | Game_High | 002_Game_High.jpg | Game view at High quality |
| 3 | 003 | Game_Low | 003_Game_Low.jpg | Game view at Low quality |
| 4 | 004 | PBR_Color | 004_PBR_Color.jpg | Base Color buffer |
| 5 | 005 | PBR_Emissive | 005_PBR_Emissive.jpg | Emissive buffer |
| 6 | 006 | PBR_Normal | 006_PBR_Normal.jpg | World Normal buffer |
| 7 | 007 | PBR_AO | 007_PBR_AO.jpg | Ambient Occlusion buffer |
| 8 | 008 | PBR_AO_Mtl | 008_PBR_AO_Mtl.jpg | Material AO channel |
| 9 | 009 | PBR_Rough | 009_PBR_Rough.jpg | Roughness buffer |
| 10 | 010 | PBR_Spec | 010_PBR_Spec.jpg | Specular buffer |
| 11 | 011 | PBR_Metallic | 011_PBR_Metallic.jpg | Metallic buffer |
| 12 | 012 | Collision_Grid | 012_Collision_Grid.jpg | Collision wireframe grid |
| 13 | 013 | Collision_Types | 013_Collision_Types.jpg | Color-coded collision volumes |
| 14 | 014 | NavMesh_On | 014_NavMesh_On.jpg | Navigation mesh visible |
| 15 | 015 | NavMesh_Off | 015_NavMesh_Off.jpg | Navigation mesh hidden |
| 16 | 016 | Material_Issues | 016_Material_Issues.jpg | Material validation overlay |

---

## Folder Naming Pattern

```
{issue_code}_{branch}_{location}/
```

**Examples**:
- `BUGFIX-1234_main_loc1/`
- `ISSUE-5678_feature-art-fixes_loc3/`

---

## Notes

- All screenshots use JPEG format
- Prefix ensures correct sorting in file explorers
- Order can be rearranged by changing the Order column
