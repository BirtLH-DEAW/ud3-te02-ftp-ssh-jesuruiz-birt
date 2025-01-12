# Utilizamos una imagen oficial de Ubuntu
FROM ubuntu:18.04

# Damos información sobre la imagen que estamos creando
LABEL \
    version="1.0" \
    description="Ubuntu + Apache2 + virtual host" \
    maintainer="usuarioBIRT <usuarioBIRT@birt.eus>"

# Actualizamos la lista de paquetes e instalamos nano y apache2
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nano apache2 && \
    rm -rf /var/lib/apt/lists/*

# Creamos directorios para los sitios web y configuraciones
RUN mkdir -p /var/www/html/sitio1 /var/www/html/sitio2

# Copiamos archivos al contenedor
COPY index1.html index2.html sitio1.conf sitio2.conf sitio1.key sitio1.cer /

# Movemos los archivos a sus ubicaciones adecuadas
RUN mv /index1.html /var/www/html/sitio1/index.html && \
    mv /index2.html /var/www/html/sitio2/index.html && \
    mv /sitio1.conf /etc/apache2/sites-available/sitio1.conf && \
    mv /sitio2.conf /etc/apache2/sites-available/sitio2.conf && \
    mv /sitio1.key /etc/ssl/private/sitio1.key && \
    mv /sitio1.cer /etc/ssl/certs/sitio1.cer

# Habilitamos los sitios y el módulo SSL
RUN a2ensite sitio1.conf && \
    a2ensite sitio2.conf && \
    a2enmod ssl

# Exponemos los puertos
EXPOSE 80
EXPOSE 443

# Comando por defecto al iniciar el contenedor
CMD ["apache2-foreground"]
