# GraphSense Dashboard Alternatives

## 🚨 Known Issue: Dashboard Build Problem

The graphsense-dashboard has a known build issue related to `tree-sitter` native compilation during Docker build. This is **NOT critical** as all GraphSense functionality is available through alternative methods.

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
curl "http://localhost:9000/telestai/addresses/YOUR_ADDRESS/txs"

# Get address neighbors (for peel chain tracking)
curl "http://localhost:9000/telestai/addresses/YOUR_ADDRESS/neighbors"

# Get transaction details
curl "http://localhost:9000/telestai/txs/TX_HASH"

# Get address entity/cluster information
curl "http://localhost:9000/telestai/addresses/YOUR_ADDRESS/entity"
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
            txs = api.get_address_txs("telestai", current_address)
            
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
suspect_address = "YOUR_TELESTAI_ADDRESS"
results = analyze_peel_chain(suspect_address)

print(f"Peel chain analysis for {suspect_address}:")
for step in results:
    print(f"  Step {step['depth']}: {step['amount_sent']} TEL sent to {step['destination_address']}")
    print(f"    Change: {step['change_amount']} TEL to {step['change_address']} ({step['change_ratio']:.1%})")
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
with DbFactory().from_config('prod', 'telestai') as db:
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

## 📊 Dashboard Fix Future Roadmap

If you want to fix the dashboard later:

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