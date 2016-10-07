class DevicesController < ApplicationController
  before_action :auth

  def index
    devices = current_team.devices.select("name", "board", "status").all
    render json: { devices: devices }
  end

  def update
    device = current_team.devices.where(name: device_params[:name]).first
    if device == nil
      render status: :not_found, json: { error: "The device not found." }
      return
    end

    device.board  = device_params[:board]
    device.status = device_params[:status]
    device.tag    = device_params[:tag]
    device.save!
  end

  def status
    device = current_team.devices.where(name: device_params[:name]).first_or_initialize
    device.board  = device_params[:board]
    device.status = device_params[:status]
    device.save!

    deployment  = get_deployment(device_params[:name])
    latest_version = deployment ? deployment.id.to_s : 'X'
    render body: latest_version
  end

  def image
    deployment = get_deployment(device_params[:name])
    unless deployment
      return head :not_found
    end

    # TODO: replace send_file with a redirection
    # XXX: introduce image ID
    # Since BaseOS does not support redirection we cannot use it.
    filepath = deployment.file.current_path
    filesize = File.size?(filepath)
    
    partial = false # send whole data by default
    if request.headers["Range"]
      m = request.headers['Range'].match(/bytes=(?<offset>\d+)-(?<offset_end>\d*)/)
      if m
        partial = true
        offset = m[:offset].to_i
        offset_end =  (m[:offset_end] == "") ? filesize : m[:offset_end].to_i
        length = offset_end - offset

        if offset < 0 || length < 0
          return head :bad_request
        end

        if offset + length > filesize || offset == filesize
          # Parsing Content-Length in BaseOS is hassle for me. Set X-End-Of-File
          # to indicate that BaseOS have downloaded whole file data.
          response.header['X-End-Of-File'] = "yes"
          return head :partial_content
        end
      end
    end

    if partial
      response.header['Content-Length'] = "#{length}"
      response.header['Content-Range']  = "bytes #{offset}-#{offset_end}/#{filesize}"
      send_data IO.binread(filepath, length, offset),
                status: :partial_content, disposition: "inline"
    else
      send_file deployment.file.current_path, status: :ok
    end
  end

  private

  def get_deployment(device_name)
    device = current_team.devices.find_by_name(device_name)
    unless device
      logger.info "the device not found"
      return nil
    end

    if device.apps == []
      logger.info "the device is not associated to an app"
      return nil
    end

    # TODO: support multi-apps
    app = device.apps.first

    deployment = Deployment.where(app: app,
                                  board: device.board,
                                  tag: [device.tag, nil]).order("created_at").last

    unless deployment
      logger.info "no deployments"
      return nil
    end

    deployment
  end

  def device_params
    params.permit(:name, :board, :status, :tag)
  end
end
