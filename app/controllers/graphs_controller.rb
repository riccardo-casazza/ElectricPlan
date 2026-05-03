class GraphsController < ApplicationController
  def show
    @dwelling = Dwelling.includes(
      electrical_panels: {
        residual_current_devices: {
          breakers: :items
        }
      }
    ).find(params[:id])
  end
end
