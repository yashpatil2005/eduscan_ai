import os
import tempfile
import fitz  # PyMuPDF
import ocrmypdf
import requests
import json
import urllib.parse
import base64
from flask import Flask, request, jsonify
from PIL import Image
import pytesseract
from youtube_search import YoutubeSearch

# --- Configuration ---
API_KEY = os.getenv("OPENROUTER_API_KEY")
if not API_KEY:
    raise ValueError("OPENROUTER_API_KEY environment variable is not set")
MODEL_ID = "deepseek/deepseek-r1-0528-qwen3-8b:free"
API_URL = "https://openrouter.ai/api/v1/chat/completions"

app = Flask(__name__)

# --- Helper Functions for Note Summarization ---

def extract_text_from_pdf(pdf_path):
    """Performs OCR on a PDF and extracts its text content."""
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_output:
        output_path = temp_output.name
    try:
        ocrmypdf.ocr(pdf_path, output_path, deskew=True, use_threads=True, force_ocr=True)
        doc = fitz.open(output_path)
        text = "".join(page.get_text() for page in doc)
        doc.close()
        return text
    finally:
        os.remove(pdf_path)
        if os.path.exists(output_path):
            os.remove(output_path)

def extract_text_from_images(image_files):
    """Extracts text from a list of image files using Tesseract OCR."""
    full_text = ""
    for image_file in image_files:
        try:
            img = Image.open(image_file)
            full_text += pytesseract.image_to_string(img) + "\n\n"
        except Exception as e:
            print(f"Could not process image {image_file.filename}: {e}")
    return full_text

def get_ai_generated_study_pack(text_content):
    """Sends extracted text to the AI and gets a full study pack."""
    prompt = f"""
    Based on the following educational notes, generate a comprehensive study pack. The output MUST be a valid JSON object.

    Notes:
    ---
    {text_content[:8000]}
    ---

    Provide the following in a JSON format:
    1.  "summary": A concise, easy-to-understand summary of the key points (around 200-300 words).
    2.  "youtube_search_terms": An array of 3 short, relevant search terms for finding related YouTube videos.
    3.  "concept_diagram": A concept map in Mermaid flowchart syntax (e.g., "graph TD; A[Start] --> B(Process);").
    4.  "flashcards": An array of 5 JSON objects, where each object has a "question" and an "answer".
    """
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": MODEL_ID,
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"}
    }

    response = requests.post(API_URL, headers=headers, json=payload)
    response.raise_for_status()
    
    ai_response_data = json.loads(response.json()["choices"][0]["message"]["content"])
    
    search_terms = ai_response_data.get("youtube_search_terms", [])
    youtube_links = []
    for term in search_terms:
        try:
            results = YoutubeSearch(term, max_results=1).to_dict()
            if results:
                video_id = results[0]['id']
                youtube_links.append(f"https://www.youtube.com/watch?v={video_id}")
        except Exception as e:
            print(f"YouTube search failed for term '{term}': {e}")

    mermaid_syntax = ai_response_data.get("concept_diagram", "graph TD; A[No Diagram];")
    encoded_mermaid = base64.b64encode(mermaid_syntax.encode('utf-8')).decode('utf-8')
    concept_diagram_url = f"https://mermaid.ink/img/{encoded_mermaid}?bgColor=FFFFFF"

    return {
        "summary": ai_response_data.get("summary", "No summary could be generated."),
        "youtube_links": youtube_links,
        "concept_diagram_url": concept_diagram_url,
        "flashcards": ai_response_data.get("flashcards", [])
    }

# --- API Routes ---

@app.route("/summarize-pdf", methods=["POST"])
def summarize_pdf_route():
    if "pdf" not in request.files:
        return jsonify({"error": "No PDF file part"}), 400
    
    pdf_file = request.files["pdf"]
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_input:
        pdf_file.save(temp_input.name)
        input_path = temp_input.name
    
    try:
        text = extract_text_from_pdf(input_path)
        if not text.strip():
            return jsonify({"error": "No text found in PDF"}), 400
        
        study_pack = get_ai_generated_study_pack(text)
        return jsonify(study_pack)
        
    except Exception as e:
        print(f"❌ SERVER ERROR: {e}")
        return jsonify({"error": "An internal server error occurred", "details": str(e)}), 500

# --- **NEW**: Route for the "Ask Sakhi" chat feature ---
@app.route("/ask-sakhi", methods=["POST"])
def ask_sakhi_route():
    data = request.get_json()
    if not data or "prompt" not in data:
        return jsonify({"error": "No prompt provided"}), 400

    user_prompt = data["prompt"]

    try:
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": MODEL_ID,
            "messages": [
                {"role": "system", "content": "You are Sakhi, a friendly and helpful AI study assistant for students. Keep your answers concise and easy to understand."},
                {"role": "user", "content": user_prompt}
            ]
        }

        response = requests.post(API_URL, headers=headers, json=payload)
        response.raise_for_status()

        result = response.json()
        ai_response = result["choices"][0]["message"]["content"]
        
        return jsonify({"response": ai_response})

    except requests.exceptions.RequestException as e:
        print(f"❌ API REQUEST ERROR: {e}")
        return jsonify({"error": "Failed to connect to AI service", "details": str(e)}), 503
    except Exception as e:
        print(f"❌ SERVER ERROR: {e}")
        return jsonify({"error": "An internal server error occurred", "details": str(e)}), 500

# TODO: Add the /summarize-images route here later using the same pattern

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
