# ========== FRONTEND BUILD (React) ==========
FROM node:18 AS frontend-builder
WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package*.json ./
RUN npm install

# Copy frontend source
COPY frontend/ ./

# Build optimized React production bundle
RUN npm run build


# ========== BACKEND BUILD (Spring Boot) ==========
FROM maven:3.9.9-eclipse-temurin-21 AS backend-builder
WORKDIR /app

# Copy backend pom.xml and download dependencies
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B

# Copy backend source
COPY backend/src ./src

# Copy built frontend into Spring Boot static folder
COPY --from=frontend-builder /app/frontend/build ./src/main/resources/static

# Build the final JAR
RUN mvn clean package -DskipTests


# ========== FINAL RUNTIME IMAGE ==========
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Add non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy the JAR from the builder stage
COPY --from=backend-builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
