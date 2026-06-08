class AdjustRubricasCteCatalogUniqueCode < ActiveRecord::Migration[8.1]
	def change
		remove_index :rubricas_cte_catalog_rubrics, name: "idx_rcte_catalog_table_code"
		add_index :rubricas_cte_catalog_rubrics, :cte_code, unique: true, name: "idx_rcte_catalog_unique_cte_code"
	end
end