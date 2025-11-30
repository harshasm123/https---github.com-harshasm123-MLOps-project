# Git Commands for Cloud Engineers - MLOps Platform

## Quick Reference Guide for Cloud/DevOps Engineers

---

## Initial Setup

### Configure Git Identity
```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Verify configuration
git config --list
```

### Clone Repository
```bash
# Clone via HTTPS
git clone https://github.com/your-org/mlops-platform.git
cd mlops-platform

# Clone via SSH (recommended for frequent commits)
git clone git@github.com:your-org/mlops-platform.git
cd mlops-platform
```

---

## Daily Workflow

### Check Status
```bash
# See what files have changed
git status

# See detailed changes
git diff

# See changes in a specific file
git diff infrastructure/cloudformation-template.yaml
```

### Stage and Commit Changes
```bash
# Stage specific files
git add deploy.sh
git add infrastructure/cicd-pipeline.yaml

# Stage all changed files
git add .

# Stage all files in a directory
git add infrastructure/

# Commit with message
git commit -m "Fix: Update CI/CD pipeline to use external buildspecs"

# Commit with detailed message
git commit -m "Fix: CodePipeline configuration size limit

- Moved inline buildspecs to separate files
- Created buildspec.yml, buildspec-test.yml, buildspec-deploy.yml
- Fixes 50,000 character limit error in CodePipeline"
```

### Push Changes
```bash
# Push to main branch
git push origin main

# Push to a specific branch
git push origin feature/cicd-improvements

# Force push (use with caution!)
git push origin main --force
```

---

## Branch Management

### Create and Switch Branches
```bash
# Create new branch
git branch feature/update-lambda-functions

# Switch to branch
git checkout feature/update-lambda-functions

# Create and switch in one command
git checkout -b feature/update-lambda-functions

# Switch back to main
git checkout main
```

### List Branches
```bash
# List local branches
git branch

# List all branches (local and remote)
git branch -a

# List remote branches only
git branch -r
```

### Merge Branches
```bash
# Switch to main branch
git checkout main

# Merge feature branch into main
git merge feature/update-lambda-functions

# Delete merged branch
git branch -d feature/update-lambda-functions
```

---

## Working with Remote Repository

### Fetch and Pull
```bash
# Fetch changes from remote (doesn't merge)
git fetch origin

# Pull changes from remote (fetch + merge)
git pull origin main

# Pull with rebase (cleaner history)
git pull --rebase origin main
```

### View Remote Information
```bash
# List remote repositories
git remote -v

# Show remote details
git remote show origin
```

---

## Infrastructure Changes

### Update CloudFormation Templates
```bash
# Check what changed
git diff infrastructure/cloudformation-template.yaml

# Stage and commit
git add infrastructure/cloudformation-template.yaml
git commit -m "Update: Add new Lambda function to CloudFormation template"
git push origin main
```

### Update Deployment Scripts
```bash
# Stage deployment script changes
git add deploy.sh

# Commit with descriptive message
git commit -m "Improve: Add --full flag to deploy.sh for complete deployment"

# Push changes
git push origin main
```

### Update IAM Policies
```bash
# Review changes
git diff infrastructure/deployment-iam-policy.json

# Stage and commit
git add infrastructure/deployment-iam-policy.json
git commit -m "Security: Add S3 encryption permissions to IAM policy"
git push origin main
```

---

## Rollback and Undo

### Undo Uncommitted Changes
```bash
# Discard changes in a specific file
git checkout -- deploy.sh

# Discard all uncommitted changes
git checkout -- .

# Unstage a file (keep changes)
git reset HEAD deploy.sh
```

### Undo Last Commit
```bash
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Undo last commit, keep changes unstaged
git reset HEAD~1

# Undo last commit, discard changes (DANGEROUS!)
git reset --hard HEAD~1
```

### Revert a Commit
```bash
# Create new commit that undoes a previous commit
git revert <commit-hash>

# Revert last commit
git revert HEAD
```

### View Commit History
```bash
# View commit history
git log

# View compact history
git log --oneline

# View history with graph
git log --graph --oneline --all

# View history for specific file
git log -- infrastructure/cloudformation-template.yaml
```

---

## Tagging (for Releases)

### Create Tags
```bash
# Create lightweight tag
git tag v1.0.0

# Create annotated tag (recommended)
git tag -a v1.0.0 -m "Release version 1.0.0 - Initial production deployment"

# Tag a specific commit
git tag -a v1.0.0 <commit-hash> -m "Release version 1.0.0"
```

### Push Tags
```bash
# Push specific tag
git push origin v1.0.0

# Push all tags
git push origin --tags
```

### List and Delete Tags
```bash
# List all tags
git tag

# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

---

## Stashing (Temporary Save)

### Save Work in Progress
```bash
# Stash current changes
git stash

# Stash with message
git stash save "WIP: Updating Lambda functions"

# List stashes
git stash list

# Apply most recent stash
git stash apply

# Apply and remove stash
git stash pop

# Apply specific stash
git stash apply stash@{1}

# Delete stash
git stash drop stash@{0}
```

---

## Collaboration

### Pull Requests (via GitHub CLI or Web)
```bash
# Create feature branch
git checkout -b feature/add-monitoring

# Make changes and commit
git add .
git commit -m "Add CloudWatch monitoring dashboard"

# Push branch
git push origin feature/add-monitoring

# Create PR (using GitHub CLI)
gh pr create --title "Add CloudWatch monitoring" --body "Implements monitoring dashboard for Lambda functions"
```

### Review Changes
```bash
# Fetch PR branch
git fetch origin pull/123/head:pr-123
git checkout pr-123

# Review changes
git diff main...pr-123

# Test changes
./deploy.sh

# Merge if approved
git checkout main
git merge pr-123
git push origin main
```

---

## Troubleshooting

### Resolve Merge Conflicts
```bash
# When merge conflict occurs
git status  # See conflicted files

# Edit conflicted files manually, then:
git add <resolved-file>
git commit -m "Resolve merge conflict in deploy.sh"
```

### Find Who Changed What
```bash
# See who last modified each line
git blame deploy.sh

# See changes in a specific commit
git show <commit-hash>

# Search commit messages
git log --grep="Lambda"
```

### Recover Deleted Files
```bash
# Find commit where file was deleted
git log --diff-filter=D --summary

# Restore file from specific commit
git checkout <commit-hash>^ -- path/to/file
```

---

## Best Practices for Cloud Engineers

### Commit Message Format
```bash
# Good commit messages
git commit -m "Fix: Resolve CodePipeline 50k character limit"
git commit -m "Add: New buildspec files for CI/CD pipeline"
git commit -m "Update: IAM policy with SageMaker permissions"
git commit -m "Refactor: Merge deployment scripts into single file"
git commit -m "Docs: Add Git commands reference for cloud engineers"

# Prefixes:
# Fix: Bug fixes
# Add: New features
# Update: Modifications to existing features
# Remove: Deleted files/features
# Refactor: Code restructuring
# Docs: Documentation changes
# Security: Security-related changes
```

### Before Pushing to Production
```bash
# 1. Check status
git status

# 2. Review all changes
git diff

# 3. Test locally
./prereq.sh
./deploy.sh

# 4. Commit with clear message
git add .
git commit -m "Deploy: Production release v1.2.0"

# 5. Tag the release
git tag -a v1.2.0 -m "Production release 1.2.0"

# 6. Push code and tags
git push origin main
git push origin v1.2.0
```

### Working with Infrastructure as Code
```bash
# Always review CloudFormation changes
git diff infrastructure/

# Test CloudFormation templates
aws cloudformation validate-template --template-body file://infrastructure/cloudformation-template.yaml

# Commit infrastructure changes separately
git add infrastructure/
git commit -m "Infrastructure: Update Lambda memory configuration"

# Commit application code separately
git add backend/lambda/
git commit -m "Lambda: Add error handling to training handler"
```

---

## Emergency Procedures

### Rollback Production Deployment
```bash
# 1. Find last good commit
git log --oneline

# 2. Create rollback branch
git checkout -b rollback/emergency-fix

# 3. Reset to last good commit
git reset --hard <last-good-commit-hash>

# 4. Force push (emergency only!)
git push origin rollback/emergency-fix --force

# 5. Deploy from rollback branch
git checkout rollback/emergency-fix
./deploy.sh
```

### Quick Hotfix
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-lambda-bug

# 2. Make fix
# Edit files...

# 3. Commit and push
git add .
git commit -m "Hotfix: Critical bug in inference Lambda"
git push origin hotfix/critical-lambda-bug

# 4. Merge to main
git checkout main
git merge hotfix/critical-lambda-bug
git push origin main

# 5. Tag hotfix
git tag -a v1.2.1 -m "Hotfix: Critical Lambda bug"
git push origin v1.2.1
```

---

## Useful Aliases

Add these to your `~/.gitconfig`:

```bash
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --all
    amend = commit --amend --no-edit
```

Usage:
```bash
git st              # Instead of git status
git co main         # Instead of git checkout main
git visual          # Pretty commit graph
```

---

## Integration with AWS

### Commit After Successful Deployment
```bash
# Deploy infrastructure
./deploy.sh --full

# If successful, commit deployment info
git add DEPLOYMENT_INFO.txt
git commit -m "Deploy: Update deployment info for $(date +%Y-%m-%d)"
git push origin main
```

### Track CloudFormation Stack Changes
```bash
# Before making changes
aws cloudformation describe-stacks --stack-name mlops-platform-dev > stack-before.json

# Make changes and deploy
git add infrastructure/cloudformation-template.yaml
git commit -m "Update: Add new DynamoDB table"
./deploy.sh

# After deployment
aws cloudformation describe-stacks --stack-name mlops-platform-dev > stack-after.json

# Compare
diff stack-before.json stack-after.json
```

---

## Quick Command Reference

```bash
# Daily workflow
git pull origin main              # Get latest changes
git checkout -b feature/my-work   # Create feature branch
# ... make changes ...
git add .                         # Stage changes
git commit -m "Add: New feature"  # Commit
git push origin feature/my-work   # Push to remote

# Check what's happening
git status                        # Current state
git log --oneline                 # Recent commits
git diff                          # Uncommitted changes

# Undo mistakes
git checkout -- file.txt          # Discard file changes
git reset HEAD~1                  # Undo last commit
git revert <commit>               # Revert specific commit

# Collaboration
git fetch origin                  # Get remote changes
git pull --rebase origin main     # Update with rebase
git push origin main              # Push changes
```

---

## Resources

- [Official Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

---

**Remember**: Always test infrastructure changes in a dev environment before pushing to production!
