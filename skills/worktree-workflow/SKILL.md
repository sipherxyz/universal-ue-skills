---
name: worktree-workflow
description: This skill should be used when implementing features in isolation using git worktrees. Triggers on "create worktree", "isolated workspace", "parallel development", or when starting implementation that should not affect main workspace.
---

# Git Worktree Workflow Skill

Manage isolated workspaces for parallel feature development.

## When to Use

- Starting implementation that should be isolated
- Working on multiple features simultaneously
- Need clean workspace separate from experiments
- Want to preserve main workspace state

## Process

### Create Worktree

```bash
# Create feature branch from main
git worktree add ../s2-{feature-slug} -b feature/{feature-slug} main

# Navigate to worktree
cd ../s2-{feature-slug}
```

### Verify Setup

```bash
# Confirm branch
git branch --show-current

# Confirm isolation
pwd
```

### Work in Worktree

1. Implement changes in isolated workspace
2. Commit incrementally (one task = one commit)
3. Push to remote for backup

### Merge Back

```bash
# In worktree, push changes
git push -u origin feature/{feature-slug}

# Return to main workspace
cd ../s2

# Merge or create PR
git checkout main
git pull
git merge feature/{feature-slug}
# Or: gh pr create
```

### Cleanup

```bash
# Remove worktree
git worktree remove ../s2-{feature-slug}

# Delete branch if merged
git branch -d feature/{feature-slug}
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Use descriptive slugs | Easy to identify worktrees |
| Commit frequently | Small, reviewable changes |
| Push regularly | Backup and collaboration |
| Clean up after merge | Avoid stale worktrees |

## Worktree Commands Reference

```bash
# List worktrees
git worktree list

# Add worktree
git worktree add <path> -b <branch> <start-point>

# Remove worktree
git worktree remove <path>

# Prune stale entries
git worktree prune
```

## Integration

This skill integrates with:
- `/ugm:implement` - Creates worktree at start
- `/ugm:review` - Reviews changes in worktree
- `/github-workflow:github-create-pr` - Creates PR from worktree branch

## Legacy Metadata

```yaml
skill: worktree-workflow
invoke: /ugm:worktree-workflow
```
