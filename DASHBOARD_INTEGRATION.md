# GraphSense Dashboard Integration with Tree-Sitter Fix

## 🎯 Overview

This integration moves the tree-sitter compilation fix from the `graphsense-dashboard` submodule into the main Avian-Blockchain-Analysis project workflow, ensuring the fix is always applied when building the dashboard.

## 📁 File Structure

```
Avian-Blockchain-Analysis/
├── docker/
│   ├── graphsense-dashboard-fixed.Dockerfile    # Main fix (Alpine-based)
│   └── graphsense-dashboard-ubuntu.Dockerfile   # Alternative (Ubuntu-based)
├── setup-dashboard-fix.sh                       # Automated setup script
├── docker-compose.yml                           # Updated to use fixed Dockerfile
└── Makefile                                     # Enhanced with dashboard commands
```

## 🔧 Integration Details

### **1. Fixed Dockerfiles Location**
- **Primary**: `docker/graphsense-dashboard-fixed.Dockerfile`
- **Alternative**: `docker/graphsense-dashboard-ubuntu.Dockerfile`

### **2. Docker Compose Configuration**
The `docker-compose.yml` now references the fixed Dockerfile:

```yaml
graphsense-dashboard:
  build:
    context: ./graphsense-dashboard
    dockerfile: ../docker/graphsense-dashboard-fixed.Dockerfile
```

### **3. Enhanced Makefile Commands**

#### **Build Commands**
```bash
make build                    # Core services only
make build-dashboard          # Dashboard with tree-sitter fix
make build-dashboard-ubuntu   # Dashboard with Ubuntu base (alternative)
make build-all               # All services including dashboard
```

#### **Service Management**
```bash
make start                   # Core services only
make start-dashboard         # Dashboard only
make start-with-dashboard    # All services including dashboard
```

## 🚀 Quick Start

### **Option 1: Automated Setup**
```bash
# Run the automated setup script
./setup-dashboard-fix.sh

# Build and start all services
make build-all
make start-with-dashboard
make init-db
```

### **Option 2: Manual Setup**
```bash
# 1. Copy fixed Dockerfiles (if not already done)
cp graphsense-dashboard/Dockerfile.fixed docker/graphsense-dashboard-fixed.Dockerfile

# 2. Build all services
make build-all

# 3. Start with dashboard
make start-with-dashboard

# 4. Initialize database
make init-db
```

## 🔍 Verification

Once setup is complete, verify the dashboard is working:

```bash
# Check service status
make status

# Verify dashboard accessibility
curl http://localhost:8080

# Check REST API
curl http://localhost:9000/health
```

## 🛠️ Troubleshooting

### **Dashboard Build Fails**
Try the Ubuntu-based alternative:
```bash
# Use Ubuntu base instead of Alpine
docker-compose build graphsense-dashboard --build-arg DOCKERFILE=../docker/graphsense-dashboard-ubuntu.Dockerfile
```

### **Tree-Sitter Still Failing**
1. Check Docker resources (increase memory/CPU)
2. Clear Docker cache: `docker system prune -f`
3. Rebuild from scratch: `make clean && make build-all`

### **Submodule Issues**
If the dashboard submodule needs updates:
```bash
git submodule update --remote graphsense-dashboard
./setup-dashboard-fix.sh  # Re-apply the fix
```

## 📋 Maintenance Workflow

### **When Updating Submodules**
```bash
# 1. Update submodules
git submodule update --remote

# 2. Re-apply dashboard fix
./setup-dashboard-fix.sh

# 3. Rebuild if needed
make build-dashboard
```

### **Adding New Dockerfile Fixes**
1. Create new Dockerfile in `docker/` directory
2. Update `docker-compose.yml` dockerfile path
3. Add corresponding Makefile target
4. Test the new configuration

## 🔄 Integration Benefits

1. **Version Control**: Fixed Dockerfiles are tracked in main repository
2. **Automation**: Setup script applies fixes automatically
3. **Flexibility**: Multiple Dockerfile options available
4. **Consistency**: Same fix applied across all environments
5. **Maintenance**: Easy to update and maintain fixes

## 🎯 Next Steps

The dashboard should now build successfully without tree-sitter compilation errors. The integration ensures:

- ✅ Tree-sitter native compilation works
- ✅ Dashboard builds in Docker environment
- ✅ Fix is preserved across submodule updates
- ✅ Multiple fallback options available
- ✅ Automated setup and maintenance

Access your working dashboard at: **http://localhost:8080** 🎉
