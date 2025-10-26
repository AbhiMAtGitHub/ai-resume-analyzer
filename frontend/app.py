# Copyright (c) 2025 Abhishek M. All rights reserved.

import os
import time

import requests
import streamlit as st


API_BASE_URL = os.getenv("API_BASE_URL", "https://api.resumeanalyzer.com")

st.set_page_config(
    page_title="AI Resume Analyzer",
    page_icon="🤖",
    layout="centered",
)

st.title("🧠 AI Resume Analyzer")
st.markdown("Analyze your resume against any Job Description and get **AI-powered feedback**!")

st.markdown("---")

resume_file = st.file_uploader("📄 Upload Resume (PDF)", type=["pdf"])
jd_file = st.file_uploader("📑 Upload Job Description (PDF)", type=["pdf"])

analyze_btn = st.button("🚀 Analyze Resume", type="primary")

if analyze_btn:
    if not resume_file or not jd_file:
        st.error("⚠️ Please upload both Resume and Job Description files.")
        st.stop()

    job_id = str(int(time.time()))

    with st.spinner("🔗 Requesting secure upload links..."):
        try:
            resp = requests.post(
                f"{API_BASE_URL}/generate-presigned-urls",
                json={"job_id": job_id, "files": ["resume.pdf", "jd.pdf"]},
                timeout=15,
            )
            resp.raise_for_status()
            data = resp.json()
            upload_urls = data["upload_urls"]
            s3_keys = data["s3_keys"]
            st.success("Presigned URLs received.")
        except Exception as e:
            st.error(f"Failed to get presigned URLs: {e}")
            st.stop()

    with st.spinner("Uploading your files securely..."):
        try:
            for filename, url in upload_urls.items():
                file_obj = resume_file if filename == "resume.pdf" else jd_file
                put_resp = requests.put(url, data=file_obj.read())
                if put_resp.status_code != 200:
                    raise RuntimeError(f"Failed upload for {filename}")
            st.success("Files uploaded successfully.")
        except Exception as e:
            st.error(f"Upload failed: {e}")
            st.stop()

    with st.spinner("Starting AI analysis pipeline..."):
        try:
            start_resp = requests.post(
                f"{API_BASE_URL}/start-analysis",
                json={
                    "job_id": job_id,
                    "resume_key": s3_keys[0],
                    "jd_key": s3_keys[1],
                },
                timeout=20,
            )
            start_resp.raise_for_status()
            st.success("Analysis started successfully.")
        except Exception as e:
            st.error(f"Failed to start analysis: {e}")
            st.stop()

    with st.spinner("Processing... (this may take ~30-60 seconds)"):
        result = None
        max_retries = 24
        for _ in range(max_retries):
            try:
                get_resp = requests.get(
                    f"{API_BASE_URL}/get-analysis",
                    params={"job_id": job_id},
                    timeout=10,
                )
                if get_resp.status_code == 200:
                    result = get_resp.json()
                    if result.get("fit_score"):
                        break
            except Exception:
                pass
            time.sleep(5)

        if not result:
            st.warning("Analysis is still running. Please refresh in a minute.")
            st.stop()

    st.markdown("---")
    st.header("AI Resume Analysis Results")

    st.metric("Job Fit Score", f"{result.get('fit_score', 0)}%")

    if result.get("missing_skills"):
        st.markdown("### Missing Skills")
        st.write(", ".join(result["missing_skills"]))

    if result.get("resume_improvements"):
        st.markdown("### Resume Improvement Suggestions")
        for tip in result["resume_improvements"]:
            st.markdown(f"- {tip}")

    if result.get("ats_tips"):
        st.markdown("### ATS Optimization Tips")
        for tip in result["ats_tips"]:
            st.markdown(f"- {tip}")
