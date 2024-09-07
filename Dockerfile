# Stage 1: Build the application
FROM openjdk:17-slim AS build_image

# Install Maven
RUN apt update && apt install maven git -y

# Clone the repository and build the project
RUN git clone https://github.com/devopshydclub/vprofile-project.git
WORKDIR /vprofile-project
RUN git checkout docker && mvn install

# Stage 2: Set up the Tomcat server
FROM tomcat:10-jdk17

# Remove default web apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR file from the build stage
COPY --from=BUILD_IMAGE /vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

# Expose port and set the command to run Tomcat
EXPOSE 8080
CMD ["catalina.sh", "run"]