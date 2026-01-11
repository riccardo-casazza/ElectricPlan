class ResidualCurrentDeviceTypesController < ApplicationController
  before_action :set_residual_current_device_type, only: %i[ show edit update destroy ]

  # GET /residual_current_device_types or /residual_current_device_types.json
  def index
    @residual_current_device_types = ResidualCurrentDeviceType.all
  end

  # GET /residual_current_device_types/1 or /residual_current_device_types/1.json
  def show
  end

  # GET /residual_current_device_types/new
  def new
    @new_residual_current_device_type = ResidualCurrentDeviceType.new
    @residual_current_device_types = ResidualCurrentDeviceType.all
    render :index
  end

  # GET /residual_current_device_types/1/edit
  def edit
    @residual_current_device_types = ResidualCurrentDeviceType.all
    @new_residual_current_device_type = @residual_current_device_type
    render :index
  end

  # POST /residual_current_device_types or /residual_current_device_types.json
  def create
    @residual_current_device_type = ResidualCurrentDeviceType.new(residual_current_device_type_params)

    respond_to do |format|
      if @residual_current_device_type.save
        format.html { redirect_to residual_current_device_types_path, notice: "Residual current device type was successfully created." }
        format.json { render :show, status: :created, location: @residual_current_device_type }
      else
        @new_residual_current_device_type = @residual_current_device_type
        @residual_current_device_types = ResidualCurrentDeviceType.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @residual_current_device_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /residual_current_device_types/1 or /residual_current_device_types/1.json
  def update
    respond_to do |format|
      if @residual_current_device_type.update(residual_current_device_type_params)
        format.html { redirect_to residual_current_device_types_path, notice: "Residual current device type was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @residual_current_device_type }
      else
        @new_residual_current_device_type = @residual_current_device_type
        @residual_current_device_types = ResidualCurrentDeviceType.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @residual_current_device_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /residual_current_device_types/1 or /residual_current_device_types/1.json
  def destroy
    @residual_current_device_type.destroy!

    respond_to do |format|
      format.html { redirect_to residual_current_device_types_path, notice: "Residual current device type was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_residual_current_device_type
      @residual_current_device_type = ResidualCurrentDeviceType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def residual_current_device_type_params
      params.expect(residual_current_device_type: [ :name ])
    end
end
