from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import os, requests, json, time, logging
from datetime import datetime
from typing import Optional, Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
LLAMA_SERVER_URL = os.getenv("LLAMA_SERVER_URL", "http://llama:8000")
CINTARA_NODE_URL = os.getenv("CINTARA_NODE_URL", "http://cintara-node:26657")

app = FastAPI(
    title="Cintara LLM Bridge",
    description="AI-powered blockchain monitoring and analysis",
    version="1.0.0"
)

# Pydantic models
class TransactionRequest(BaseModel):
    transaction: Dict[str, Any]

class ChatRequest(BaseModel):
    message: str

class NodeStatusResponse(BaseModel):
    status: str
    details: Dict[str, Any]
    timestamp: str

@app.get("/health")
def health():
    """Health check for both LLM server and blockchain node"""
    llm_status = "unknown"
    node_status = "unknown"
    
    # Check LLM server
    try:
        r = requests.get(f"{LLAMA_SERVER_URL}/health", timeout=2)
        llm_status = "ok" if r.status_code == 200 else "degraded"
    except Exception as e:
        logger.error(f"LLM health check failed: {e}")
        llm_status = "down"
    
    # Check Cintara node
    try:
        r = requests.get(f"{CINTARA_NODE_URL}/status", timeout=2)
        if r.status_code == 200:
            data = r.json()
            node_status = "synced" if not data.get("result", {}).get("sync_info", {}).get("catching_up", True) else "syncing"
        else:
            node_status = "degraded"
    except Exception as e:
        logger.error(f"Node health check failed: {e}")
        node_status = "down"
    
    overall_status = "ok" if llm_status == "ok" and node_status in ["ok", "synced", "syncing"] else "degraded"
    
    return {
        "status": overall_status,
        "components": {
            "llm_server": llm_status,
            "blockchain_node": node_status
        },
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/node/status")
def get_node_status():
    """Get detailed blockchain node status"""
    try:
        r = requests.get(f"{CINTARA_NODE_URL}/status", timeout=5)
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="Node unreachable")
        
        data = r.json()
        result = data.get("result", {})
        sync_info = result.get("sync_info", {})
        node_info = result.get("node_info", {})
        
        return NodeStatusResponse(
            status="healthy",
            details={
                "catching_up": sync_info.get("catching_up", True),
                "latest_block_height": sync_info.get("latest_block_height", "0"),
                "latest_block_time": sync_info.get("latest_block_time", ""),
                "node_id": node_info.get("id", ""),
                "moniker": node_info.get("moniker", ""),
                "network": node_info.get("network", ""),
                "version": node_info.get("version", "")
            },
            timestamp=datetime.utcnow().isoformat()
        )
    except requests.RequestException as e:
        logger.error(f"Failed to get node status: {e}")
        raise HTTPException(status_code=503, detail="Node unreachable")

@app.post("/node/diagnose")
async def diagnose_node():
    """LLM-powered node diagnostics"""
    try:
        # Gather node information
        status_response = requests.get(f"{CINTARA_NODE_URL}/status", timeout=5)
        net_info_response = requests.get(f"{CINTARA_NODE_URL}/net_info", timeout=5)
        
        node_data = {}
        if status_response.status_code == 200:
            node_data["status"] = status_response.json()
        
        if net_info_response.status_code == 200:
            node_data["net_info"] = net_info_response.json()
        
        # Create diagnostic prompt
        prompt = f"""
        Analyze this Cintara blockchain node and provide diagnostic insights:
        
        Node Data: {json.dumps(node_data, indent=2)}
        
        Please analyze:
        1. Node sync status and health
        2. Network connectivity issues
        3. Performance concerns
        4. Recommendations for improvement
        
        Return a JSON response with: {{
            "health_score": "good|warning|critical",
            "issues": ["list of issues found"],
            "recommendations": ["list of recommendations"],
            "summary": "brief summary"
        }}
        """
        
        # Get LLM analysis
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 300,
                "temperature": 0.1,
                "stop": ["}"]
            },
            timeout=30
        )
        
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="LLM analysis failed")
        
        llm_response = r.json()
        content = llm_response.get("content", "").strip()
        
        # Try to parse JSON response
        try:
            # Add closing brace if missing
            if not content.endswith("}"):
                content += "}"
            analysis = json.loads(content)
        except json.JSONDecodeError:
            analysis = {
                "health_score": "unknown",
                "issues": ["Failed to parse LLM response"],
                "recommendations": ["Check LLM server configuration"],
                "summary": content
            }
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return {
            "diagnosis": analysis,
            "node_data": node_data,
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except requests.RequestException as e:
        logger.error(f"Node diagnosis failed: {e}")
        raise HTTPException(status_code=503, detail="Diagnosis failed")

@app.post("/analyze")
async def analyze_transaction(req: TransactionRequest):
    """Analyze transaction with LLM"""
    try:
        tx = req.transaction
        prompt = f"""
        Analyze this blockchain transaction for security risks and insights:
        
        Transaction: {json.dumps(tx, indent=2)}
        
        Provide analysis in JSON format:
        {{
            "risk_level": "low|medium|high",
            "risks": ["list of identified risks"],
            "insights": ["transaction insights"],
            "recommendation": "action recommendation"
        }}
        """
        
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 200,
                "temperature": 0.0,
                "stop": ["}"]
            },
            timeout=30
        )
        
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="LLM analysis failed")
        
        llm_response = r.json()
        content = llm_response.get("content", "").strip()
        
        # Try to parse JSON response
        try:
            if not content.endswith("}"):
                content += "}"
            analysis = json.loads(content)
        except json.JSONDecodeError:
            analysis = {
                "risk_level": "unknown",
                "risks": ["Failed to parse analysis"],
                "insights": [content],
                "recommendation": "Manual review required"
            }
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return JSONResponse({
            "analysis": analysis,
            "transaction": tx,
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Transaction analysis failed: {e}")
        raise HTTPException(status_code=500, detail="Analysis failed")

@app.get("/node/logs")
async def analyze_logs():
    """Analyze recent node logs for issues"""
    try:
        logs_content = []
        
        # Option 1: Try to read from shared volume (Cintara node logs)
        log_path = os.getenv("LOG_PATH", "/shared/logs")
        if os.path.exists(f"{log_path}"):
            try:
                # Look for common log files
                for log_file in ["cintarad.log", "node.log", "tendermint.log"]:
                    full_path = os.path.join(log_path, log_file)
                    if os.path.exists(full_path):
                        with open(full_path, 'r') as f:
                            # Read last 100 lines
                            lines = f.readlines()[-100:]
                            logs_content.extend([f"[{log_file}] {line.strip()}" for line in lines])
            except Exception as e:
                logger.warning(f"Could not read log files: {e}")
        
        # Option 2: Try to read from data directory
        data_log_path = "/shared/.tmp-cintarad"
        if not logs_content and os.path.exists(data_log_path):
            try:
                # Check for log files in the node data directory
                for root, dirs, files in os.walk(data_log_path):
                    for file in files:
                        if file.endswith('.log') or 'log' in file.lower():
                            full_path = os.path.join(root, file)
                            try:
                                with open(full_path, 'r') as f:
                                    lines = f.readlines()[-50:]  # Last 50 lines per file
                                    logs_content.extend([f"[{file}] {line.strip()}" for line in lines])
                            except Exception:
                                continue
            except Exception as e:
                logger.warning(f"Could not read data directory logs: {e}")
        
        # Option 3: Use Docker container logs as fallback
        if not logs_content:
            try:
                import subprocess
                # Try to get docker logs (requires docker command in container)
                result = subprocess.run(
                    ["docker", "logs", "--tail", "50", "cintara-node"],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    logs_content = result.stdout.split('\n')[-50:]
            except Exception as e:
                logger.warning(f"Could not get docker logs: {e}")
        
        # If still no logs, get RPC-based info
        if not logs_content:
            try:
                # Get recent blocks/transactions as proxy for activity
                status_response = requests.get(f"{CINTARA_NODE_URL}/status", timeout=3)
                if status_response.status_code == 200:
                    status_data = status_response.json()
                    sync_info = status_data.get("result", {}).get("sync_info", {})
                    
                    logs_content = [
                        f"Node Status: Latest block height {sync_info.get('latest_block_height', '0')}",
                        f"Catching up: {sync_info.get('catching_up', 'unknown')}",
                        f"Latest block time: {sync_info.get('latest_block_time', 'unknown')}",
                        "No direct log file access available - using RPC status"
                    ]
            except Exception as e:
                logs_content = [f"Could not fetch any log data: {str(e)}"]
        
        # Prepare logs for LLM analysis
        recent_logs = '\n'.join(logs_content[-50:]) if logs_content else "No logs available"
        
        prompt = f"""
        Analyze these recent Cintara blockchain node logs for issues and patterns:
        
        Recent Log Entries:
        {recent_logs}
        
        Please analyze for:
        1. Error messages or warnings
        2. Performance issues
        3. Sync problems
        4. Network connectivity issues
        5. Any concerning patterns
        
        Return JSON response:
        {{
            "log_health": "good|warning|error",
            "issues": ["list of specific issues found"],
            "patterns": ["notable patterns observed"],
            "recommendations": ["suggested actions"],
            "summary": "brief overall assessment"
        }}
        """
        
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 250,
                "temperature": 0.1,
                "stop": ["}"]
            },
            timeout=25
        )
        
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="LLM log analysis failed")
        
        llm_response = r.json()
        content = llm_response.get("content", "").strip()
        
        # Try to parse JSON response
        try:
            if not content.endswith("}"):
                content += "}"
            analysis = json.loads(content)
        except json.JSONDecodeError:
            analysis = {
                "log_health": "unknown",
                "issues": ["Failed to parse LLM analysis"],
                "patterns": [content],
                "recommendations": ["Check log parsing configuration"],
                "summary": "Analysis parsing failed"
            }
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return {
            "log_analysis": analysis,
            "logs_found": len(logs_content),
            "log_sample": logs_content[-10:] if logs_content else [],  # Last 10 lines as sample
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Log analysis failed: {e}")
        raise HTTPException(status_code=500, detail="Log analysis failed")

@app.get("/node/transactions/{block_height}")
async def analyze_block_transactions(block_height: int):
    """Analyze transactions in a specific block"""
    try:
        # Get block data from Cintara node
        block_response = requests.get(f"{CINTARA_NODE_URL}/block?height={block_height}", timeout=10)
        
        if block_response.status_code != 200:
            raise HTTPException(status_code=404, detail=f"Block {block_height} not found")
        
        block_data = block_response.json()
        block_result = block_data.get("result", {})
        block_info = block_result.get("block", {})
        transactions = block_info.get("data", {}).get("txs", [])
        
        if not transactions:
            return {
                "block_height": block_height,
                "transaction_count": 0,
                "analysis": "No transactions in this block",
                "timestamp": datetime.utcnow().isoformat()
            }
        
        # Prepare transaction data for LLM analysis
        tx_summary = {
            "block_height": block_height,
            "transaction_count": len(transactions),
            "block_time": block_info.get("header", {}).get("time", ""),
            "transactions": transactions[:5]  # Analyze first 5 transactions to avoid token limit
        }
        
        prompt = f"""
        Analyze these blockchain transactions from block {block_height}:
        
        Block Data: {json.dumps(tx_summary, indent=2)}
        
        Please analyze:
        1. Transaction patterns and types
        2. Potential security concerns
        3. Unusual activity or anomalies
        4. Network health indicators
        
        Return JSON response:
        {{
            "overall_assessment": "normal|suspicious|concerning",
            "transaction_patterns": ["observed patterns"],
            "security_issues": ["any security concerns"],
            "recommendations": ["suggested actions"],
            "summary": "brief analysis summary"
        }}
        """
        
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 300,
                "temperature": 0.1,
                "stop": ["}"]
            },
            timeout=30
        )
        
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="Transaction analysis failed")
        
        llm_response = r.json()
        content = llm_response.get("content", "").strip()
        
        # Parse LLM response
        try:
            if not content.endswith("}"):
                content += "}"
            analysis = json.loads(content)
        except json.JSONDecodeError:
            analysis = {
                "overall_assessment": "unknown",
                "transaction_patterns": ["Analysis parsing failed"],
                "security_issues": [content],
                "recommendations": ["Manual review recommended"],
                "summary": "Could not parse LLM analysis"
            }
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return {
            "block_height": block_height,
            "transaction_count": len(transactions),
            "analysis": analysis,
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except requests.RequestException as e:
        logger.error(f"Block transaction analysis failed: {e}")
        raise HTTPException(status_code=503, detail="Could not fetch block data")
    except Exception as e:
        logger.error(f"Transaction analysis error: {e}")
        raise HTTPException(status_code=500, detail="Analysis failed")

@app.post("/chat")
async def chat_with_ai(req: Request):
    """Interactive AI chat about node status and blockchain insights"""
    try:
        payload = await req.json()
        user_message = payload.get("message", "")
        
        if not user_message:
            raise HTTPException(status_code=400, detail="Message is required")
        
        # Gather current node context
        node_context = {}
        try:
            # Get node status
            status_response = requests.get(f"{CINTARA_NODE_URL}/status", timeout=3)
            if status_response.status_code == 200:
                node_context["status"] = status_response.json()
            
            # Get network info
            net_response = requests.get(f"{CINTARA_NODE_URL}/net_info", timeout=3)
            if net_response.status_code == 200:
                node_context["network"] = net_response.json()
        except Exception as e:
            logger.warning(f"Could not gather node context: {e}")
        
        # Create context-aware prompt
        context_summary = ""
        if node_context:
            status_info = node_context.get("status", {}).get("result", {})
            sync_info = status_info.get("sync_info", {})
            node_info = status_info.get("node_info", {})
            
            context_summary = f"""
            Current Node Context:
            - Node ID: {node_info.get('id', 'unknown')[:8]}...
            - Moniker: {node_info.get('moniker', 'unknown')}
            - Network: {node_info.get('network', 'unknown')}
            - Latest Block: {sync_info.get('latest_block_height', '0')}
            - Catching Up: {sync_info.get('catching_up', 'unknown')}
            - Peer Count: {node_context.get('network', {}).get('result', {}).get('n_peers', '0')}
            """
        
        prompt = f"""
        You are an expert blockchain analyst helping monitor a Cintara node. 
        Answer the user's question about their blockchain node using the provided context.
        
        {context_summary}
        
        User Question: {user_message}
        
        Provide a helpful, accurate response about the node's status, performance, or blockchain operations. 
        If you need more specific data that isn't available in the context, suggest how to get it.
        Keep responses concise but informative.
        """
        
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 400,
                "temperature": 0.3,
                "stop": ["\n\nUser:", "\n\nQuestion:"]
            },
            timeout=30
        )
        
        if r.status_code != 200:
            raise HTTPException(status_code=503, detail="AI chat service unavailable")
        
        llm_response = r.json()
        ai_response = llm_response.get("content", "").strip()
        
        if not ai_response:
            ai_response = "I apologize, but I couldn't generate a response. Please try rephrasing your question."
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return {
            "message": user_message,
            "response": ai_response,
            "node_context_available": bool(node_context),
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat failed: {e}")
        raise HTTPException(status_code=500, detail="Chat service error")

@app.get("/node/peers")
async def get_node_peers():
    """Get detailed peer information with AI analysis"""
    try:
        net_response = requests.get(f"{CINTARA_NODE_URL}/net_info", timeout=5)
        
        if net_response.status_code != 200:
            raise HTTPException(status_code=503, detail="Could not fetch peer information")
        
        net_data = net_response.json()
        result = net_data.get("result", {})
        peers = result.get("peers", [])
        
        # Prepare peer data for analysis
        peer_summary = {
            "total_peers": result.get("n_peers", "0"),
            "listening": result.get("listening", False),
            "listeners": result.get("listeners", []),
            "peer_details": peers[:10]  # Analyze first 10 peers to avoid token limits
        }
        
        prompt = f"""
        Analyze this Cintara node's peer connectivity:
        
        Peer Data: {json.dumps(peer_summary, indent=2)}
        
        Assess:
        1. Peer connectivity health
        2. Geographic/network diversity
        3. Connection stability indicators
        4. Potential connectivity issues
        
        Return JSON:
        {{
            "connectivity_health": "excellent|good|fair|poor",
            "peer_diversity": "high|medium|low",
            "issues": ["list of concerns"],
            "recommendations": ["suggested improvements"],
            "summary": "brief assessment"
        }}
        """
        
        t0 = time.time()
        r = requests.post(
            f"{LLAMA_SERVER_URL}/completion",
            json={
                "prompt": prompt,
                "n_predict": 250,
                "temperature": 0.1,
                "stop": ["}"]
            },
            timeout=25
        )
        
        analysis = {"connectivity_health": "unknown", "summary": "Analysis unavailable"}
        if r.status_code == 200:
            content = r.json().get("content", "").strip()
            try:
                if not content.endswith("}"):
                    content += "}"
                analysis = json.loads(content)
            except json.JSONDecodeError:
                analysis["summary"] = content
        
        latency_ms = int((time.time() - t0) * 1000)
        
        return {
            "peer_analysis": analysis,
            "peer_count": len(peers),
            "total_peers": result.get("n_peers", 0),
            "listening": result.get("listening", False),
            "peers_sample": peers[:5],  # Return first 5 peers as sample
            "latency_ms": latency_ms,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except requests.RequestException as e:
        logger.error(f"Peer analysis failed: {e}")
        raise HTTPException(status_code=503, detail="Could not analyze peers")
    except Exception as e:
        logger.error(f"Peer analysis error: {e}")
        raise HTTPException(status_code=500, detail="Analysis failed")

# Legacy endpoint for backward compatibility
@app.post("/analyze_transaction")
async def legacy_analyze(req: Request):
    """Legacy transaction analysis endpoint"""
    payload = await req.json()
    tx_request = TransactionRequest(transaction=payload.get("transaction", {}))
    return await analyze_transaction(tx_request)