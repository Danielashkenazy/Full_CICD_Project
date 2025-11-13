
import json
from app import app

def test_main_route():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hello, Devops!" in response.data

def test_echo_route():
    client = app.test_client()
    payload = {"msg": "Hello"}
    response = client.post('/echo', json=payload)
    assert response.status_code == 200
    assert response.get_json() == payload
