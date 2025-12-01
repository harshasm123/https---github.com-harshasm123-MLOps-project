# Git Commands for Cloud Engineers

## Essential Git Commands for MLOps Platform

### Initial Setup

```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Clone repository
git clone https://github.com/your-org/mlops-platform.git
cd mlops-platform
```

### Branch Management

```bash
# Create feature branch
git checkout -b feature/medication-adherence-model

# List branches
git branch -a

# Switch branch
git checkout main

# Delete branch
git branch -d feature/medication-adherence-model

# Rename branch
git branch -m old-name new-name
```

### Committing Changes

```bash
# Check status
git status

# Stage all changes
git add .

# Stage specific file
git add src/pipelines/training_pipeline.py

# Commit changes
git commit -m "Add medication adherence training pipeline"

# Amend last commit
git commit --amend --no-edit

# View commit history
git log --oneline -10
```

### Pushing and Pulling

```bash
# Push to remote
git push origin feature/medication-adherence-model

# Pull latest changes
git pull origin main

# Fetch without merging
git fetch origin

# Push all branches
git push origin --all
```

### Merging and Rebasing

```bash
# Merge branch into main
git checkout main
git merge feature/medication-adherence-model

# Rebase branch
git rebase main

# Interactive rebase
git rebase -i HEAD~3

# Abort rebase
git rebase --abort
```

### Stashing Changes

```bash
# Stash uncommitted changes
git stash

# List stashes
git stash list

# Apply stash
git stash apply stash@{0}

# Drop stash
git stash drop stash@{0}
```

### Undoing Changes

```bash
# Discard changes in working directory
git checkout -- src/pipelines/training_pipeline.py

# Unstage file
git reset HEAD src/pipelines/training_pipeline.py

# Revert commit
git revert abc1234

# Reset to previous commit
git reset --hard HEAD~1
```

### Viewing Changes

```bash
# Show diff
git diff

# Show staged diff
git diff --staged

# Show commit details
git show abc1234

# Show file history
git log -p src/pipelines/training_pipeline.py
```

### Remote Management

```bash
# List remotes
git remote -v

# Add remote
git remote add upstream https://github.com/upstream/repo.git

# Remove remote
git remote remove upstream

# Change remote URL
git remote set-url origin https://github.com/new-org/repo.git
```

### Tags

```bash
# Create tag
git tag v1.0.0

# Push tag
git push origin v1.0.0

# List tags
git tag -l

# Delete tag
git tag -d v1.0.0
```

### Collaboration

```bash
# Create pull request (GitHub CLI)
gh pr create --title "Add medication adherence model" --body "Implements RandomForest model"

# View pull requests
gh pr list

# Merge pull request
gh pr merge 123

# Check out pull request
gh pr checkout 123
```

### Debugging

```bash
# Find commit that introduced bug
git bisect start
git bisect bad HEAD
git bisect good v1.0.0

# Search commit history
git log -S "medication_adherence" --oneline

# Show who changed each line
git blame src/pipelines/training_pipeline.py

# Find lost commits
git reflog
```

## Branching Strategies

### Git Flow Strategy (Recommended for MLOps Platform)

```
main (production)
  ├── release/v1.0.0
  └── hotfix/critical-bug

develop (staging)
  ├── feature/medication-adherence-model
  ├── feature/drift-detection
  ├── feature/dashboard-ui
  └── bugfix/training-timeout
```

#### Branch Types

**main**: Production-ready code
- Only merged from release or hotfix branches
- Tagged with version numbers
- Protected branch (requires PR review)

**develop**: Integration branch
- Base for feature branches
- Deployed to staging environment
- Protected branch (requires PR review)

**feature/**: New features
- Branch from: `develop`
- Merge back to: `develop`
- Naming: `feature/medication-adherence-model`

**bugfix/**: Bug fixes
- Branch from: `develop`
- Merge back to: `develop`
- Naming: `bugfix/training-timeout`

**release/**: Release preparation
- Branch from: `develop`
- Merge to: `main` and `develop`
- Naming: `release/v1.0.0`

**hotfix/**: Production fixes
- Branch from: `main`
- Merge to: `main` and `develop`
- Naming: `hotfix/critical-bug`

#### Git Flow Commands

```bash
# Initialize Git Flow
git flow init

# Start feature
git flow feature start medication-adherence-model

# Finish feature (merges to develop)
git flow feature finish medication-adherence-model

# Start release
git flow release start 1.0.0

# Finish release (merges to main and develop)
git flow release finish 1.0.0

# Start hotfix
git flow hotfix start critical-bug

# Finish hotfix (merges to main and develop)
git flow hotfix finish critical-bug
```

### Trunk-Based Development (Alternative)

```
main
  ├── feature/short-lived-1
  ├── feature/short-lived-2
  └── feature/short-lived-3
```

**Characteristics**:
- Short-lived branches (1-2 days max)
- Frequent merges to main
- Feature flags for incomplete features
- Continuous deployment

```bash
# Create short-lived feature branch
git checkout -b feature/quick-fix

# Make changes and commit
git add .
git commit -m "Quick fix for issue"

# Push and create PR
git push origin feature/quick-fix

# After approval, merge and delete
git checkout main
git merge feature/quick-fix
git push origin main
git branch -d feature/quick-fix
```

### GitHub Flow (Simplified)

```
main (always deployable)
  ├── feature/model-training
  ├── feature/api-endpoint
  └── feature/ui-dashboard
```

**Rules**:
1. Create branch from main
2. Make changes and commit
3. Create pull request
4. Review and discuss
5. Merge to main
6. Deploy immediately

```bash
# Create feature branch
git checkout -b feature/model-training

# Make changes
git add .
git commit -m "Add model training"

# Push and create PR
git push origin feature/model-training

# After review, merge
git checkout main
git merge feature/model-training
git push origin main
```

## MLOps Platform Branching Strategy

**Recommended**: Git Flow

### Branch Naming Conventions

```
feature/medication-adherence-model
feature/drift-detection-system
feature/dashboard-improvements

bugfix/training-timeout-issue
bugfix/inference-latency

release/v1.0.0
release/v1.1.0

hotfix/critical-security-patch
hotfix/data-corruption-fix
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Build/dependencies

**Examples**:
```
feat(training): add RandomForest algorithm support
fix(inference): resolve timeout in batch predictions
docs(api): update endpoint documentation
test(model-registry): add DynamoDB tests
```

### Pull Request Workflow

```bash
# 1. Create feature branch
git checkout -b feature/medication-adherence-model

# 2. Make changes
git add .
git commit -m "feat(model): add medication adherence prediction"

# 3. Push to remote
git push origin feature/medication-adherence-model

# 4. Create PR on GitHub
# - Add description
# - Link related issues
# - Request reviewers

# 5. Address review comments
git add .
git commit -m "Address review comments"
git push origin feature/medication-adherence-model

# 6. Merge PR (after approval)
# - Use "Squash and merge" for clean history
# - Delete branch after merge

# 7. Update local repository
git checkout develop
git pull origin develop
```

### Release Process

```bash
# 1. Create release branch
git flow release start 1.0.0

# 2. Update version numbers
# - package.json
# - requirements.txt
# - README.md

git add .
git commit -m "Bump version to 1.0.0"

# 3. Finish release
git flow release finish 1.0.0

# 4. Push to remote
git push origin main develop
git push origin --tags

# 5. Deploy to production
./deploy.sh --full-cloudfront
```

### Hotfix Process

```bash
# 1. Create hotfix branch from main
git flow hotfix start critical-bug

# 2. Fix the issue
git add .
git commit -m "fix: resolve critical bug in inference"

# 3. Finish hotfix
git flow hotfix finish critical-bug

# 4. Push to remote
git push origin main develop
git push origin --tags

# 5. Deploy hotfix
./deploy.sh --full-cloudfront
```

## Workflow Examples

### Feature Development
```bash
# Create feature branch
git checkout -b feature/new-model

# Make changes
git add .
git commit -m "Implement new model"

# Push to remote
git push origin feature/new-model

# Create pull request on GitHub
# After review and approval:
git checkout develop
git pull origin develop
git merge feature/new-model
git push origin develop
```

### Hotfix
```bash
# Create hotfix branch from main
git checkout -b hotfix/critical-bug main

# Fix bug
git add .
git commit -m "Fix critical bug"

# Merge to main
git checkout main
git merge hotfix/critical-bug
git push origin main

# Merge to develop
git checkout develop
git merge hotfix/critical-bug
git push origin develop
```

### Release
```bash
# Create release branch
git checkout -b release/v1.1.0 develop

# Update version numbers
git add .
git commit -m "Bump version to 1.1.0"

# Merge to main
git checkout main
git merge release/v1.1.0
git tag v1.1.0
git push origin main --tags

# Merge back to develop
git checkout develop
git merge release/v1.1.0
git push origin develop
```

## Best Practices

1. **Commit Often**: Small, logical commits are easier to review
2. **Write Good Messages**: Clear commit messages help future developers
3. **Pull Before Push**: Always pull latest changes before pushing
4. **Use Branches**: Never commit directly to main
5. **Review Code**: Use pull requests for code review
6. **Keep History Clean**: Use rebase for linear history
7. **Tag Releases**: Tag all production releases
8. **Protect Main**: Require pull request reviews before merging
9. **Delete Merged Branches**: Clean up after merging
10. **Sync Regularly**: Keep branches up to date with main/develop