class DevicesController < ApplicationController

  def index
    devices = Device.select("name", "board", "status").all
    render json: { devices: devices }
  end
  
  def status
    device = Device.where(name: device_params[:name]).first_or_initialize
    device.board  = device_params[:board]
    device.status = device_params[:status]
    device.save!
    head :ok
  end

  def image
    device = Device.find_by_name(device_params[:name])
    unless device
      logger.info "the device not found"
      return head :not_found
    end

    if device.apps == []
      logger.info "the device is not associated to an app"
      return head :not_found
    end

    # TODO: support multi-apps
    app = device.apps.first

    deployment = Deployment.where(app: app).order("created_at").last
    unless deployment
      logger.info "no deployments"
      return head :not_found
    end

    image = Image.where(deployment: deployment, board: device.board).first
    unless image
      logger.info "no image uploaded for the device in the deploment"
      return head :not_found
    end

    # TODO: replace send_file with a redirection
    # Since BaseOS does not support redirection we cannot use it.
    filepath = image.file.current_path
    filesize = File.size?(filepath)
    
    partial = false # send whole data by default
    if request.headers["Range"]
      m = request.headers['Range'].match(/bytes=(?<offset>\d+)-(?<offset_end>\d*)/)
      if m
        partial = true
        offset = m[:offset].to_i
        offset_end =  (m[:offset_end] == "") ? filesize : m[:offset_end].to_i
        length = offset_end - offset

        if offset < 0 || length < 0 || offset + length > filesize
          return head status: :bad_request
        end
      end
    end

    if partial
      response.header['Content-Length'] = "#{length}"
      response.header['Content-Range']  = "bytes #{offset}-#{offset_end}/#{filesize}"
      send_data IO.binread(filepath, length, offset),
                status: :partial_content, disposition: "inline"
    else
      send_file image.file.current_path, status: :ok
    end
  end

  private

  def device_params
    params.permit(:name, :board, :status)
  end
end
