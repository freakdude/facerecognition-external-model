# Use NVIDIA CUDA as the base image
FROM nvidia/cuda:11.0-base AS builder

# Copy Makefile to /app/
COPY Makefile /app/

# Install necessary libraries and tools
RUN apt-get update -yq \
    && apt-get install -yq bzip2 cmake g++ make wget python3-pip \
    && pip3 install wheel \
    && pip3 wheel -w /app/ dlib[cuda] \
    && make -C /app/ download-models

# Use NVIDIA CUDA as the base image for the second stage
FROM nvidia/cuda:11.0-base

# Copy necessary files from the builder stage
COPY --from=builder /app/dlib*.whl /tmp/
COPY --from=builder /app/vendor/ /app/vendor/
COPY facerecognition-external-model.py /app/

# Install necessary Python packages and Dlib with CUDA support
RUN apt-get update -yq \
    && apt-get install -yq python3-pip \
    && pip3 install flask numpy \
    && pip3 install --no-index -f /tmp/ dlib[cuda] \
    && rm /tmp/dlib*.whl

# Set the working directory to /app/
WORKDIR /app/

# Expose port 5000
EXPOSE 5000

# Set environment variables
ENV API_KEY=some-super-secret-api-key
ENV FLASK_APP=facerecognition-external-model.py

# Run the application
CMD flask run -h 0.0.0.0
