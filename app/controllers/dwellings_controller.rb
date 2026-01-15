class DwellingsController < ApplicationController
  before_action :set_dwelling, only: %i[ show edit update destroy ]

  # GET /dwellings or /dwellings.json
  def index
    @dwellings = Dwelling.all
  end

  # GET /dwellings/1 or /dwellings/1.json
  def show
  end

  # GET /dwellings/new
  def new
    @dwelling = Dwelling.new
  end

  # GET /dwellings/1/edit
  def edit
  end

  # POST /dwellings or /dwellings.json
  def create
    @dwelling = Dwelling.new(dwelling_params)

    respond_to do |format|
      if @dwelling.save
        format.html { redirect_to @dwelling, notice: "Dwelling was successfully created." }
        format.json { render :show, status: :created, location: @dwelling }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dwelling.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dwellings/1 or /dwellings/1.json
  def update
    respond_to do |format|
      if @dwelling.update(dwelling_params)
        format.html { redirect_to @dwelling, notice: "Dwelling was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @dwelling }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dwelling.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dwellings/1 or /dwellings/1.json
  def destroy
    @dwelling.destroy!

    respond_to do |format|
      format.html { redirect_to dwellings_path, notice: "Dwelling was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dwelling
      @dwelling = Dwelling.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def dwelling_params
      params.expect(dwelling: [ :name ])
    end
end
