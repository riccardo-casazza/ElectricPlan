class ElectricalPanelsController < ApplicationController
  before_action :set_electrical_panel, only: %i[ show edit update destroy ]

  # GET /electrical_panels or /electrical_panels.json
  def index
    @electrical_panels = ElectricalPanel.all
  end

  # GET /electrical_panels/1 or /electrical_panels/1.json
  def show
  end

  # GET /electrical_panels/new
  def new
    @new_electrical_panel = ElectricalPanel.new
    @electrical_panels = ElectricalPanel.all
    render :index
  end

  # GET /electrical_panels/1/edit
  def edit
    @electrical_panels = ElectricalPanel.all
    @new_electrical_panel = @electrical_panel
    render :index
  end

  # POST /electrical_panels or /electrical_panels.json
  def create
    @electrical_panel = ElectricalPanel.new(electrical_panel_params)

    respond_to do |format|
      if @electrical_panel.save
        format.html { redirect_to electrical_panels_path, notice: "Electrical panel was successfully created." }
        format.json { render :show, status: :created, location: @electrical_panel }
      else
        @new_electrical_panel = @electrical_panel
        @electrical_panels = ElectricalPanel.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @electrical_panel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /electrical_panels/1 or /electrical_panels/1.json
  def update
    respond_to do |format|
      if @electrical_panel.update(electrical_panel_params)
        format.html { redirect_to electrical_panels_path, notice: "Electrical panel was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @electrical_panel }
      else
        @new_electrical_panel = @electrical_panel
        @electrical_panels = ElectricalPanel.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @electrical_panel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /electrical_panels/1 or /electrical_panels/1.json
  def destroy
    @electrical_panel.destroy!

    respond_to do |format|
      format.html { redirect_to electrical_panels_path, notice: "Electrical panel was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_electrical_panel
      @electrical_panel = ElectricalPanel.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def electrical_panel_params
      params.expect(electrical_panel: [ :name, :dwelling_id, :room_id, :input_max_current, :input_cable_id ])
    end
end
