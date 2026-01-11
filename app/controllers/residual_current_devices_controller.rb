class ResidualCurrentDevicesController < ApplicationController
  before_action :set_residual_current_device, only: %i[ show edit update destroy ]

  # GET /residual_current_devices or /residual_current_devices.json
  def index
    @residual_current_devices = ResidualCurrentDevice.all
  end

  # GET /residual_current_devices/1 or /residual_current_devices/1.json
  def show
  end

  # GET /residual_current_devices/new
  def new
    @new_residual_current_device = ResidualCurrentDevice.new
    @residual_current_devices = ResidualCurrentDevice.all
    render :index
  end

  # GET /residual_current_devices/1/edit
  def edit
    @residual_current_devices = ResidualCurrentDevice.all
    @new_residual_current_device = @residual_current_device
    render :index
  end

  # POST /residual_current_devices or /residual_current_devices.json
  def create
    @residual_current_device = ResidualCurrentDevice.new(residual_current_device_params)

    respond_to do |format|
      if @residual_current_device.save
        format.html { redirect_to residual_current_devices_path, notice: "Residual current device was successfully created." }
        format.json { render :show, status: :created, location: @residual_current_device }
      else
        @new_residual_current_device = @residual_current_device
        @residual_current_devices = ResidualCurrentDevice.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @residual_current_device.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /residual_current_devices/1 or /residual_current_devices/1.json
  def update
    respond_to do |format|
      if @residual_current_device.update(residual_current_device_params)
        format.html { redirect_to residual_current_devices_path, notice: "Residual current device was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @residual_current_device }
      else
        @new_residual_current_device = @residual_current_device
        @residual_current_devices = ResidualCurrentDevice.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @residual_current_device.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /residual_current_devices/1 or /residual_current_devices/1.json
  def destroy
    @residual_current_device.destroy!

    respond_to do |format|
      format.html { redirect_to residual_current_devices_path, notice: "Residual current device was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_residual_current_device
      @residual_current_device = ResidualCurrentDevice.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def residual_current_device_params
      params.expect(residual_current_device: [ :electrical_panel_id, :row_number, :position, :max_current, :residual_current_device_type_id ])
    end
end
