# GraphSense Dashboard Alternatives

## 🚨 Known Issue: Dashboard Build Problem

The graphsense-dashboard had a known build issue related to `tree-sitter` native compilation during Docker build. **This has now been FIXED** - see `graphsense-dashboard/BUILD_FIX_README.md` for the complete solution. All GraphSense functionality is also available through alternative methods below.

## ✅ Available Alternatives

### **1. REST API Direct Access**

Access all GraphSense functionality through the REST API:

```bash
# Start core services (without dashboard)
docker-compose up -d cassandra spark-master spark-worker-1 graphsense-lib graphsense-rest

# API will be available at: http://localhost:9000
```

**Peel Chain Analysis via REST API:**

```bash
# Get address transactions
curl "http://localhost:9000/avian/addresses/YOUR_ADDRESS/txs"

# Get address neighbors (for peel chain tracking)
curl "http://localhost:9000/avian/addresses/YOUR_ADDRESS/neighbors"

# Get transaction details
curl "http://localhost:9000/avian/txs/TX_HASH"

# Get address entity/cluster information
curl "http://localhost:9000/avian/addresses/YOUR_ADDRESS/entity"
```

### **2. Python Client for Analysis**

Use the GraphSense Python client for advanced peel chain analysis:

```python
import graphsense
from graphsense.api import addresses_api

# Configure client
config = graphsense.Configuration(host="http://localhost:9000")
client = graphsense.ApiClient(config)
api = addresses_api.AddressesApi(client)

def analyze_peel_chain(start_address, max_depth=10):
    """
    Analyze potential peel chain patterns starting from an address
    """
    peel_chain = []
    current_address = start_address

    for depth in range(max_depth):
        try:
            # Get outgoing transactions
            txs = api.get_address_txs("avian", current_address)

            for tx in txs.address_txs:
                # Look for 2-output transactions (typical peel chain pattern)
                if len(tx.outputs) == 2:
                    outputs = sorted(tx.outputs, key=lambda x: x.value, reverse=True)
                    large_output = outputs[0]  # Change
                    small_output = outputs[1]  # Real destination

                    # Calculate ratio (peel chains typically >90% change)
                    total_value = large_output.value + small_output.value
                    change_ratio = large_output.value / total_value

                    if change_ratio > 0.9:  # 90%+ goes to change
                        peel_chain.append({
                            'depth': depth,
                            'tx_hash': tx.tx_hash,
                            'change_address': large_output.address,
                            'destination_address': small_output.address,
                            'amount_sent': small_output.value,
                            'change_amount': large_output.value,
                            'change_ratio': change_ratio,
                            'timestamp': tx.timestamp
                        })

                        # Follow the change address for next iteration
                        current_address = large_output.address
                        break
            else:
                # No peel chain pattern found, stop analysis
                break

        except Exception as e:
            print(f"Error analyzing address {current_address}: {e}")
            break

    return peel_chain

# Usage example
suspect_address = "YOUR_AVIAN_ADDRESS"
results = analyze_peel_chain(suspect_address)

print(f"Peel chain analysis for {suspect_address}:")
for step in results:
    print(f"  Step {step['depth']}: {step['amount_sent']} AVN sent to {step['destination_address']}")
    print(f"    Change: {step['change_amount']} AVN to {step['change_address']} ({step['change_ratio']:.1%})")
    print(f"    TX: {step['tx_hash']}")
```

### **3. Command Line Tools**

Direct CLI access for data analysis:

```bash
# Execute commands inside graphsense-lib container
docker-compose exec graphsense-lib python -m graphsenselib.cli

# Example: Get address information
docker-compose exec graphsense-lib python -c "
from graphsenselib.db import DbFactory
with DbFactory().from_config('prod', 'avian') as db:
    result = db.transformed.get_address_transactions('YOUR_ADDRESS')
    print(result)
"
```

### **4. Third-Party Visualization Tools**

You can use external tools to visualize the data:

1. **Gephi**: Export graph data and import into Gephi for visualization
2. **Cytoscape**: Network analysis and visualization
3. **Custom scripts**: Create your own visualization using libraries like:
   - `networkx` (Python)
   - `vis.js` (JavaScript)
   - `D3.js` (JavaScript)

### **5. Jupyter Notebooks**

Create interactive analysis notebooks:

```python
# Install in your local environment
pip install graphsense-python jupyter matplotlib networkx

# Create analysis notebook
import graphsense
import matplotlib.pyplot as plt
import networkx as nx

# Connect to GraphSense API
config = graphsense.Configuration(host="http://localhost:9000")
client = graphsense.ApiClient(config)

# Build transaction graph and visualize
G = nx.DiGraph()
# Add nodes and edges based on transaction data
# Visualize with matplotlib or plotly
```

## 🚀 Quick Start Without Dashboard

```bash
# 1. Start core services
make start-infra
make start-apps

# 2. Initialize database
make init-db

# 3. Test connection
make test-connection

# 4. Start ingestion
make ingest-batch

# 5. Access via API
curl http://localhost:9000/health

# 6. Use Python client
cd graphsense-python/examples
python address_analysis.py
```

## 📊 Dashboard Fix Integrated ✅

**UPDATE: The tree-sitter build issue has been INTEGRATED into the main project!**

**Quick Start with Fixed Dashboard**:
```bash
# Apply the fix (automated)
./setup-dashboard-fix.sh

# Build and start with dashboard
make build-all
make start-with-dashboard
```

**Integration Details**: See `DASHBOARD_INTEGRATION.md` for complete documentation.

**Key Benefits**:
- ✅ Fix is automatically applied from main project
- ✅ Version controlled in main repository  
- ✅ Survives submodule updates
- ✅ Multiple Dockerfile options available
- ✅ Integrated into Makefile workflow

**Manual Fix** (if needed):
The original fix files are available in `docker/` directory:
- `docker/graphsense-dashboard-fixed.Dockerfile` - Enhanced Alpine build
- `docker/graphsense-dashboard-ubuntu.Dockerfile` - Ubuntu-based alternative

**Legacy troubleshooting approaches** (for reference only):
1. **Try building outside Docker** (native environment)
2. **Use different Node.js version** (18.x or 22.x)
3. **Pre-compile native modules** in separate container
4. **Use alternative build systems** (yarn instead of npm)
5. **Build on different host OS** (Ubuntu instead of Alpine)

## 🔗 Additional Resources

- **GraphSense API Documentation**: Auto-generated OpenAPI docs at `http://localhost:9000/docs`
- **Python Client Examples**: `graphsense-python/examples/`
- **REST API Examples**: `curl` commands in this document
- **GraphSense Official Docs**: https://graphsense.info/documentation/

---

**The GraphSense ecosystem is fully functional for peel chain analysis without the web dashboard!** 🚀
