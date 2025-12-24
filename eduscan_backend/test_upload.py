import requests

url = "http://127.0.0.1:5000/summarize-pdf"
files = {"pdf": open("test.pdf", "rb")}
response = requests.post(url, files=files)

print(response.json())