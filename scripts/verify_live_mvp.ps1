# Start the local backend on 127.0.0.1:8011 before running this script.
# Creates one clearly named workout for the known demo Ali account, then records
# a partial result. Does not reset or delete existing data.
param([string]$BackendPath = (Join-Path $PSScriptRoot '..\..\athlete_os_backend'))
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendRoot = (Resolve-Path -LiteralPath $BackendPath).Path
$definesPath = Join-Path ([System.IO.Path]::GetTempPath()) ('athleteos-live-' + [guid]::NewGuid().ToString() + '.json')
try {
    Push-Location -LiteralPath $backendRoot
    try {
@'
import asyncio, json, sys
from sqlalchemy import text
from app.core.config import get_settings
from app.core.database import engine
s=get_settings()
assert s.environment == 'local' and s.database_name == 'athlete_os', 'Local demo DB required'
assert s.demo_coach_password and s.demo_athlete_password, 'Demo credentials required in backend .env'
async def preflight():
    async with engine.connect() as c:
        assert await c.scalar(text('select current_database()')) == 'athlete_os'
        assert await c.scalar(text("select count(*) from coach_athletes where coach_id='11111111-1111-4111-8111-111111111111' and athlete_id='22222222-2222-4222-8222-222222222222' and status='active' and ended_at is null")) == 1
    await engine.dispose()
asyncio.run(preflight())
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    json.dump({'RUN_LIVE_MVP': True, 'DEMO_COACH_PASSWORD': s.demo_coach_password,
               'DEMO_ATHLETE_PASSWORD': s.demo_athlete_password}, f)
print('Local demo database and assignment verified.')
'@ | & '.\.venv\Scripts\python.exe' - $definesPath
        if ($LASTEXITCODE -ne 0) { throw 'Demo preflight failed' }
    } finally { Pop-Location }
    $ready = Invoke-RestMethod 'http://127.0.0.1:8011/ready'
    if ($ready.status -ne 'ready') { throw 'Backend is not ready' }
    Push-Location -LiteralPath $projectPath
    try {
        flutter test test/live_mvp_test.dart "--dart-define-from-file=$definesPath" --reporter expanded
        if ($LASTEXITCODE -ne 0) { throw 'Live MVP verification failed' }
    } finally { Pop-Location }
} finally {
    if (Test-Path -LiteralPath $definesPath) { Remove-Item -LiteralPath $definesPath }
}
