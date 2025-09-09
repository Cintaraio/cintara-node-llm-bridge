# Cintara Node Web UI

A modern React-based web interface for managing and monitoring your Cintara blockchain node with AI-powered insights.

## Features

### 🎯 Dashboard
- Real-time system health monitoring
- Node synchronization status
- AI-powered diagnostics overview
- Peer connectivity analysis

### 💬 AI Chat
- Interactive conversation with AI about your node
- Ask questions about node status, performance, and blockchain operations
- Context-aware responses based on current node state
- Suggested questions to get started

### 📊 Node Status
- Detailed blockchain node information
- Peer connectivity analysis
- Network health monitoring
- Real-time sync status updates

### 🔍 Diagnostics
- **Overview**: AI health assessment with issues and recommendations
- **Log Analysis**: Intelligent parsing of node logs with pattern recognition
- **Block Analysis**: Transaction analysis for specific blocks
- **Debug Info**: Technical debugging information for troubleshooting

## Architecture

The web UI connects to the Cintara LLM Bridge API to provide:
- Real-time node monitoring
- AI-powered analysis and insights
- Interactive chat functionality
- Advanced diagnostics and logging

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web UI        │    │   AI Bridge      │    │   Cintara Node  │
│   (React)       │◄───┤   (FastAPI)      │◄───┤   (Official)    │
│   Port: 3000    │    │   Port: 8080     │    │   Port: 26657   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                ▲
                                │
                       ┌──────────────────┐
                       │   LLM Server     │
                       │   (llama.cpp)    │
                       │   Port: 8000     │
                       └──────────────────┘
```

## Technology Stack

- **Frontend**: React 18, React Router, Styled Components
- **Icons**: Lucide React
- **Data Visualization**: React JSON View
- **HTTP Client**: Axios
- **Build**: Create React App
- **Deployment**: Docker with Nginx

## Development

### Prerequisites
- Node.js 18 or later
- npm or yarn

### Local Development
```bash
cd web-ui
npm install
npm start
```

The app will be available at `http://localhost:3000` and will proxy API requests to `http://localhost:8080`.

### Environment Variables
- `REACT_APP_API_URL`: Base URL for the API (default: `/api`)
- `NODE_ENV`: Environment (development/production)

## Docker Deployment

The web UI is automatically included when you run the full Cintara Node stack:

```bash
# From the main project directory
docker compose up -d
```

This will start:
- LLM Server (port 8000)
- AI Bridge (port 8080) 
- Web UI (port 3000)

### Accessing the Web Interface

Once all services are running, open your browser to:
```
http://localhost:3000
```

## API Integration

The web UI communicates with the Cintara LLM Bridge through these endpoints:

### Health & Status
- `GET /health` - System health check
- `GET /node/status` - Detailed node status
- `GET /node/peers` - Peer connectivity info

### AI Features  
- `POST /chat` - Interactive AI chat
- `POST /node/diagnose` - AI-powered diagnostics
- `GET /node/logs` - Log analysis with AI insights

### Advanced Analytics
- `GET /node/transactions/{block_height}` - Block transaction analysis
- `GET /debug/llm` - LLM server debug information

## Usage Guide

### 1. Dashboard Overview
The dashboard provides a quick overview of your node's health:
- **System Health**: Overall status of all components
- **Node Status**: Blockchain sync status and network info
- **AI Diagnostics**: Intelligent health assessment
- **Network Peers**: Connectivity and peer diversity analysis

### 2. AI Chat Interface
Use the chat feature to:
- Ask about node performance: *"How is my node performing?"*
- Check for issues: *"Are there any problems I should know about?"*
- Get maintenance advice: *"What maintenance should I perform?"*
- Understand blockchain operations: *"What does catching up mean?"*

### 3. Node Status Monitoring
Monitor detailed node metrics:
- Block synchronization progress
- Peer connections and network health
- Node configuration and version info
- Real-time status updates

### 4. Advanced Diagnostics
Access powerful diagnostic tools:
- **AI Health Analysis**: Get intelligent assessments of node health
- **Log Analysis**: AI-powered parsing of node logs for issues
- **Block Analysis**: Analyze transactions in specific blocks
- **Debug Information**: Technical details for troubleshooting

## Security Features

- Content Security Policy (CSP) headers
- XSS protection
- Frame options security
- Secure proxy configuration
- Health check endpoints

## Performance

- Gzip compression for static assets
- Optimized asset caching
- Efficient React component structure
- Lazy loading and code splitting ready
- Docker multi-stage builds for minimal image size

## Customization

The UI can be customized by:
1. Modifying styled-components themes
2. Updating the color scheme in CSS variables
3. Adding new dashboard widgets
4. Extending API integration for additional features

## Troubleshooting

### Web UI not loading
1. Check that all Docker services are running: `docker compose ps`
2. Verify the AI Bridge is healthy: `curl http://localhost:8080/health`
3. Check web UI logs: `docker compose logs web-ui`

### API connection issues
1. Ensure the AI Bridge is accessible on port 8080
2. Check nginx proxy configuration
3. Verify CORS settings if running in development

### Chat not responding
1. Check LLM server status: `curl http://localhost:8000/health`
2. Verify AI Bridge can communicate with LLM: `curl http://localhost:8080/debug/llm`
3. Check for sufficient system resources (CPU/memory)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Part of the Cintara Node LLM Bridge project - see main project LICENSE file.