FROM pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    wget \
    curl

# Copy modified requirements file (we'll install CLIP separately)
COPY requirements.txt .

# Remove the vision_aided_loss line if it exists
RUN sed -i '/vision_aided_loss/d' requirements.txt

# Install Python dependencies
RUN pip install -r requirements.txt

# Install additional dependencies
RUN pip install peft==0.12.0
RUN pip install huggingface-hub==0.25.0

# Create directories for checkpoints
RUN mkdir -p /app/checkpoints

# Copy only the edge_to_image_loras.pkl checkpoint
COPY checkpoints/edge_to_image_loras.pkl /app/checkpoints/

# Copy the application code
COPY gradio_canny2image.py .
COPY style.css .
COPY src/ ./src/
COPY assets/ ./assets/

ENV HF_HOME=/data/huggingface

# Set environment variables for Gradio
ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860

# Expose the port
EXPOSE 7860

# Entry point shell script to verify the model
RUN echo '#!/bin/bash\n\
if [ ! -f "/app/checkpoints/edge_to_image_loras.pkl" ]; then\n\
    echo "Error: Required checkpoint file edge_to_image_loras.pkl not found. The container cannot run."\n\
    exit 1\n\
fi\n\
\n\
# Run the application\n\
python gradio_canny2image.py\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Command to run the Gradio app
CMD ["/app/entrypoint.sh"]