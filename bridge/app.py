from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import os, requests, json, time

# ---- Config ----
LLAMA_SERVER_URL = os.getenv("LLAMA_SERVER_URL", "http://llama:8000")
NODE_RPC = os.getenv("NODE_RPC", "http://cintara-node:26657")  # reachable inside compose

app = FastAPI()

# ---- Health ----
@app.get("/health")
def health():
    llama_ok = False
    node_ok = False
    try:
        r = requests.get(f"{LLAMA_SERVER_URL}/health", timeout=1.5)
        llama_ok = (r.status_code == 200)
    except Exception:
        llama_ok = False
    try:
        r = requests.get(f"{NODE_RPC}/status", timeout=1.5)
        node_ok = (r.status_code == 200)
    except Exception:
        node_ok = False
    return {"llama": "ok" if llama_ok else "down", "node": "ok" if node_ok else "down"}

# ---- JSON Grammar (GBNF) to force pure JSON output) ----
SCHEMA_GRAMMAR = r'''
root ::= "{" ws "\"risks\"" ws ":" ws "[" ws risk (ws "," ws risk)* ws "]" ws "}"
risk ::= "{" ws "\"risk_type\"" ws ":" ws string ws "," ws "\"explanation\"" ws ":" ws string ws "}"
string ::= "\"" chars "\""
chars ::= ( [^"\\] | "\\" ["\\/bfnrt] )*
ws ::= [ \t\n\r]*
'''

def _llama_completion(prompt: str, use_grammar: bool = True, n_predict: int = 160):
    body = {
        "prompt": prompt,
        "temperature": 0.0,
        "n_predict": n_predict,
        "stop": []
    }
    if use_grammar:
        body["grammar"] = SCHEMA_GRAMMAR
    return requests.post(f"{LLAMA_SERVER_URL}/completion", json=body, timeout=120)

def _extract_json(text: str):
    # Fallback to slice the first {...} blob
    try:
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            return json.loads(text[start:end+1])
    except Exception:
        pass
    return {"risks":[{"risk_type":"UnstructuredOutput","explanation":(text or "")[:400]}]}

def _analyze_payload(payload_obj: dict):
    prompt = (
        "You are an API that must output ONLY JSON matching this structure:\n"
        "{ \"risks\": [ { \"risk_type\": string, \"explanation\": string } ... ] }\n"
        "No markdown, no commentary, no code fences. Return 1-3 concise risks.\n\n"
        f"Data: {json.dumps(payload_obj, separators=(',',':'))}\n"
    )
    t0 = time.time()
    # First try grammar-constrained
    r = _llama_completion(prompt, use_grammar=True, n_predict=160)
    content = (r.json().get("content")
               or (r.json().get("choices",[{}])[0].get("content") if r.json().get("choices") else None))
    if not content:
        # Fallback without grammar
        r2 = _llama_completion(prompt, use_grammar=False, n_predict=120)
        content = (r2.json().get("content")
                   or (r2.json().get("choices",[{}])[0].get("content") if r2.json().get("choices") else ""))
    latency_ms = int((time.time() - t0) * 1000)
    parsed = _extract_json(content or "")
    return parsed, latency_ms

# ---------- Endpoint 1: /analyze (manual JSON input) ----------
@app.post("/analyze")
async def analyze(req: Request):
    body = await req.json()
    tx = body.get("transaction", {})
    result, latency_ms = _analyze_payload({"transaction": tx})
    return JSONResponse({"analysis": result, "latency_ms": latency_ms})

# ---------- Endpoint 2: /analyze_tx (fetch from node by hash) ----------
@app.post("/analyze_tx")
async def analyze_tx(req: Request):
    body = await req.json()
    tx_hash = (body.get("hash") or "").strip()
    if not tx_hash:
        return JSONResponse({"error": "Missing 'hash' in body"}, status_code=400)

    # Tendermint/Comet expects hex hash; keep whatever caller provides
    try:
        r = requests.get(f"{NODE_RPC}/tx", params={"hash": tx_hash}, timeout=10)
        r.raise_for_status()
        tx_data = r.json()
    except Exception as e:
        return JSONResponse({"error": f"Node RPC error: {e}"}, status_code=502)

    # Optionally enrich with /status or /block data if you want:
    # status = requests.get(f"{NODE_RPC}/status", timeout=4).json()

    # Analyze the fetched tx_data
    result, latency_ms = _analyze_payload({"tx_hash": tx_hash, "tx": tx_data})
    return JSONResponse({"analysis": result, "transaction": tx_data, "latency_ms": latency_ms})
