from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.post("/some_endpoint")
async def some_endpoint(request: Request):
    data = await request.json()
    return JSONResponse({"output": {"output_type": 1}})

@app.post("/predict_interval")
async def predict_interval(request: Request):
    data = await request.json()
    return JSONResponse({"output": {"output_type": 1}})

@app.post("/predict_variant")
async def predict_variant(request: Request):
    data = await request.json()
    return JSONResponse({"reference_output": {"output_type": 1}})

@app.post("/score_interval")
async def score_interval(request: Request):
    data = await request.json()
    return JSONResponse({"output": {"interval_data": {}}}) 