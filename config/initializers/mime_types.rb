# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register "model/stl", :stl
Mime::Type.register "model/obj", :obj
Mime::Type.register "model/3mf", :threemf, [], ["3mf"]
Mime::Type.register "text/plain", :ply
Mime::Type.register "application/octet-stream", :blend
Mime::Type.register "application/octet-stream", :mix
Mime::Type.register "application/octet-stream", :abc
Mime::Type.register "model/step", :stp
Mime::Type.register "application/octet-stream", :lys
Mime::Type.register "application/octet-stream", :lyt
Mime::Type.register "application/octet-stream", :chitubox

Mime::Type.register "image/webp", :webp
