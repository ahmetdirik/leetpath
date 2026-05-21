from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI(
    title="LeetPath",
    description="AI-powered NeetCode 150 tracker",
    version="0.1.0",
)

# Static files (CSS, JS, images) - serve from /static URL path
app.mount("/static", StaticFiles(directory="src/leetpath/static"), name="static")

# Template engine
templates = Jinja2Templates(directory="src/leetpath/templates")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/", response_class=HTMLResponse)
async def root(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "title": "LeetPath",
            "heading": "LeetPath",
            "message": "AI-powered NeetCode 150 tracker. Coming soon.",
        },
    )
