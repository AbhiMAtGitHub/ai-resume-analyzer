# Copyright (c) 2025 Abhishek M. All rights reserved.

import uuid

import requests
import streamlit as st


# --- Securely load API URL from Streamlit Secrets ---
API_URL = st.secrets.get("API_URL", None)

st.set_page_config(page_title="AI Resume vs JD Analyzer", page_icon="📄")

st.title("📄 AI Resume vs JD Analyzer")
st.caption("Upload your Resume and Job Description to generate AI insights.")

# --- Sanity check for API URL ---
if not API_URL:
    st.error("❌ Missing API_URL in Streamlit Secrets!")
    st.stop()

st.info(f"Using backend API: {API_URL}")

# --- UI for uploads ---
col1, col2 = st.columns(2)
with col1:
    uploaded_resume = st.file_uploader("Upload Resume (PDF)", type=["pdf"])
with col2:
    uploaded_jd = st.file_uploader("Upload JD (PDF)", type=["pdf"])

# --- Generate request_id ---
request_id = st.text_input("Request ID", value=f"REQ-{uuid.uuid4().hex[:6].upper()}")

# --- Submit Button ---
if st.button("🚀 Analyze"):
    if not uploaded_resume or not uploaded_jd:
        st.warning("Please upload both Resume and JD files before submitting.")
        st.stop()

    try:
        with st.spinner("Fetching pre-signed URLs from Lambda..."):
            response = requests.post(API_URL, json={"request_id": request_id})
            st.write("🔍 API status code:", response.status_code)
            st.write("🔍 Raw response text:", response.text)
            response.raise_for_status()
            data = response.json()
            st.write("🔍 Parsed JSON:", data)

            # ✅ Extract presigned URLs from correct key
            upload_urls = data.get("upload_urls", {})

            # Try to find resume & jd URLs dynamically (no hardcoding)
            resume_url = next((v for k, v in upload_urls.items() if "resume" in k.lower()), None)
            jd_url = next((v for k, v in upload_urls.items() if "jd" in k.lower()), None)

            if not (resume_url and jd_url):
                st.error("❌ Lambda response missing expected upload URLs.")
                st.stop()

        with st.spinner("Uploading files to S3..."):
            resume_upload = requests.put(resume_url, data=uploaded_resume.getvalue())
            jd_upload = requests.put(jd_url, data=uploaded_jd.getvalue())

        if resume_upload.status_code == 200 and jd_upload.status_code == 200:
            st.success("✅ Files uploaded successfully!")
            st.info("Files are now being processed downstream. Check results soon!")
        else:
            st.error("❌ Upload failed. Check API Gateway or S3 permissions.")

    except requests.exceptions.RequestException as re:
        st.error(f"Network error calling API Gateway: {re}")

    except Exception as e:
        st.error(f"Unexpected error: {e}")
