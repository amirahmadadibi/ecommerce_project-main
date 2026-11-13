-- Temporary anon INSERT policies for one-time data migration
CREATE POLICY "tmp_ins_category" ON shop.category FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_products" ON shop.products FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_banner" ON shop.banner FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_gallery" ON shop.gallery FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_variants_type" ON shop.variants_type FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_variants" ON shop.variants FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_properties" ON shop.properties FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_comment" ON shop.comment FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "tmp_ins_users" ON shop.users FOR INSERT TO anon WITH CHECK (true);
