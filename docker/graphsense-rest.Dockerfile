# Custom GraphSense REST Dockerfile with Cassandra protocol version 4 fix
FROM python:3.11-slim

WORKDIR /srv/graphsense-rest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy the GraphSense REST source code
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create a patch for the protocol version issue
RUN sed -i 's/protocol_version=5,/protocol_version=int(self.config.get("protocol_version", 4)),/' gsrest/db/cassandra.py

# Create instance directory for config
RUN mkdir -p instance

# Expose port
EXPOSE 9000

# Start the application
CMD ["python", "-m", "gsrest.service"]
