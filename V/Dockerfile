# # Use a newer, secure Node.js runtime
# FROM node:20.19.6-alpine3.22

# # Actualizar Busybox y paquetes del sistema
# RUN apk update && apk upgrade

# # Set the working directory in the container
# WORKDIR /usr/src/app

# # Copy package.json and package-lock.json to the working directory
# COPY package*.json ./

# # Install app dependencies
# RUN npm install

# # Copy the rest of the application code to the working directory
# COPY . .

# # Expose the port the app runs on
# EXPOSE 3000

# # Define the command to run the application
# CMD ["npm", "start"]

FROM node:14
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
