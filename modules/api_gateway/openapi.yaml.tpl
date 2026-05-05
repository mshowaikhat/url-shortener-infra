swagger: "2.0"
info:
  title: ${api_id}
  description: |
    GCP API Gateway proxy for the URL shortener write API. Routes /api/* and
    health checks to the shortener Cloud Run service. The X-API-Key header is
    forwarded unchanged; the shortener validates it.
  version: 1.0.0
host: apigateway.googleapis.com
schemes:
  - https
produces:
  - application/json
consumes:
  - application/json
paths:
  /api/urls:
    post:
      operationId: createShortUrl
      summary: Create a short URL
      x-google-backend:
        address: ${shortener_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      parameters:
        - in: header
          name: X-API-Key
          type: string
          required: true
        - in: body
          name: body
          required: true
          schema:
            type: object
            properties:
              long_url:
                type: string
            required:
              - long_url
      responses:
        "201":
          description: Created
        "400":
          description: Bad Request
        "401":
          description: Unauthorized
  /api/urls/{code}:
    get:
      operationId: getShortUrl
      summary: Look up a short URL by code
      x-google-backend:
        address: ${shortener_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      parameters:
        - in: path
          name: code
          type: string
          required: true
        - in: header
          name: X-API-Key
          type: string
          required: true
      responses:
        "200":
          description: OK
        "401":
          description: Unauthorized
        "404":
          description: Not Found
  /livez:
    get:
      operationId: livez
      summary: Liveness probe (passthrough)
      x-google-backend:
        address: ${shortener_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      responses:
        "200":
          description: OK
  /readyz:
    get:
      operationId: readyz
      summary: Readiness probe (passthrough)
      x-google-backend:
        address: ${shortener_url}
        path_translation: APPEND_PATH_TO_ADDRESS
      responses:
        "200":
          description: OK
        "503":
          description: Degraded
