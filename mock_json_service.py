from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.post("/predict_sequence")
async def predict_sequence(request: Request):
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


# New endpoints to fully cover service
@app.post("/score_variant")
async def score_variant(request: Request):
    data = await request.json()
    return JSONResponse({"output": {"variant_data": {}}})


@app.post("/score_ism_variant")
async def score_ism_variant(request: Request):
    data = await request.json()
    return JSONResponse({"output": {"variant_data": {}}})


@app.post("/metadata")
async def metadata(request: Request):
    data = await request.json()
    return JSONResponse({"output_metadata": []})
