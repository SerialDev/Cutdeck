from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Cutdeck API",
    description="Backend API for Cutdeck powered by DaggyD",
    version="0.1.0",
)

# CORS middleware for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "Cutdeck backend is running with DaggyD",
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "Cutdeck API",
        "version": "0.1.0",
        "docs": "/docs",
    }


@app.get("/daggyd/test")
async def test_daggyd():
    """Test DaggyD installation by running a simple counter graph"""
    from DaggyD.pregel_core import pregel, add_channel, add_node, run

    # Create a simple counter graph to verify DaggyD works
    p = pregel()
    p = add_channel(p, "count", "LastValue", initial_value=0)

    def increment(inputs):
        val = inputs.get("count", 0)
        return {"out": val + 1} if val < 5 else None

    p = add_node(
        p, "counter", increment, subscribe_to=["count"], write_to={"out": "count"}
    )

    result = run(p)

    return {
        "status": "success",
        "message": "DaggyD test passed!",
        "result": {"final_count": result["count"]},
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
