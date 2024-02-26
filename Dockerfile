# Stage 1: Build JavaScript files
FROM node:16 AS js-builder
WORKDIR /app
COPY mlflow/server/js /app
RUN yarn install && yarn build

# Stage 2: Build and setup everything in one stage
FROM python:3.8-slim-bullseye AS wheel-builder
WORKDIR /mlflow

# Copy the MLflow project files into the Docker container
COPY . /mlflow

# Copy built JavaScript files from js-builder
COPY --from=js-builder /app/build /mlflow/mlflow/server/js/build

# Build the Python wheel for MLflow
RUN python setup.py bdist_wheel

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Install the Python wheel with extras
RUN for whl in /mlflow/dist/*.whl; do pip install "$whl[extras]"; done && rm -rf /mlflow/dist

FROM python:3.8-slim-bullseye

WORKDIR /mlflow

COPY --from=wheel-builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Set the default command
CMD ["bash"]