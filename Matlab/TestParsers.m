%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Test GMSH parsers for msh-files written in format version v2.2 and V4.1
%
%      Coded by Manuel A. Diaz @ Pprime | Univ-Poitiers, 2022.01.21
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

%% Unpartitioned Domains 2D

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/square_tri_v2.msh');
figure(1); subplot(231); viewNodes(V,info);
figure(2); subplot(231); viewLineElements(V,LE,info);
figure(3); subplot(231); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/square_quad_v2.msh');
figure(1); subplot(232); viewNodes(V,info);
figure(2); subplot(232); viewLineElements(V,LE,info);
figure(3); subplot(232); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/square_mixed_v2.msh');
figure(1); subplot(233); viewNodes(V,info);
figure(2); subplot(233); viewLineElements(V,LE,info);
figure(3); subplot(233); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/square_tri_v4.msh');
figure(1); subplot(234); viewNodes(V,info);
figure(2); subplot(234); viewLineElements(V,LE,info);
figure(3); subplot(234); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/square_quad_v4.msh');
figure(1); subplot(235); viewNodes(V,info);
figure(2); subplot(235); viewLineElements(V,LE,info);
figure(3); subplot(235); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/square_mixed_v4.msh');
figure(1); subplot(236); viewNodes(V,info);
figure(2); subplot(236); viewLineElements(V,LE,info);
figure(3); subplot(236); viewSurfaceElements(V,SE,info);

%% Unpartitioned Domains 3D

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/square_extruded_prism_v2.msh');
figure(4); subplot(231); viewNodes(V,info,false);
figure(5); subplot(231); viewSurfaceElements(V,SE,info);
figure(6); subplot(231); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/square_extruded_hex_v2.msh');
figure(4); subplot(232); viewNodes(V,info,false);
figure(5); subplot(232); viewSurfaceElements(V,SE,info);
figure(6); subplot(232); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/square_extruded_mixed_v2.msh');
figure(4); subplot(233); viewNodes(V,info,false);
figure(5); subplot(233); viewSurfaceElements(V,SE,info);
figure(6); subplot(233); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/square_extruded_prism_v4.msh');
figure(4); subplot(234); viewNodes(V,info,false);
figure(5); subplot(234); viewSurfaceElements(V,SE,info);
figure(6); subplot(234); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/square_extruded_hex_v4.msh');
figure(4); subplot(235); viewNodes(V,info,false);
figure(5); subplot(235); viewSurfaceElements(V,SE,info);
figure(6); subplot(235); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/square_extruded_mixed_v4.msh');
figure(4); subplot(236); viewNodes(V,info,false);
figure(5); subplot(236); viewSurfaceElements(V,SE,info);
figure(6); subplot(236); viewVolumetricElements(V,VE,info);

%% Patitioned Domains 2D & 3D

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/simple_rectangle_v2.msh');
figure(7); subplot(221); viewNodes(V,info);
figure(8); subplot(221); viewLineElements(V,LE,info);
figure(9); subplot(221); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/simple_rectangle_v4.msh');
figure(7); subplot(222); viewNodes(V,info);
figure(8); subplot(222); viewLineElements(V,LE,info);
figure(9); subplot(222); viewSurfaceElements(V,SE,info);

[V,VE,SE,LE,~,~,info] = GMSHparserV2('../meshes/simple_box_v2.msh');
figure(7); subplot(223); viewNodes(V,info);
figure(8); subplot(223); viewLineElements(V,LE,info);
figure(9); subplot(223); viewSurfaceElements(V,SE,info);
figure(10); subplot(221); viewPartVolumes(V,VE,1,info);
figure(10); subplot(222); viewPartVolumes(V,VE,2,info);

[V,VE,SE,LE,PE,~,info] = GMSHparserV4('../meshes/simple_box_v4.msh');
figure(7); subplot(224); viewNodes(V,info);
figure(8); subplot(224); viewLineElements(V,LE,info);
figure(9); subplot(224); viewSurfaceElements(V,SE,info);
figure(10); subplot(223); viewPartVolumes(V,VE,1,info);
figure(10); subplot(224); viewPartVolumes(V,VE,2,info);

%% Higher-Order Curved Meshes 2D & 3D

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/sector_mixed_p2_v2.msh');
figure(11); subplot(231); viewNodes(V,info,false);
figure(12); subplot(231); viewLineElements(V,LE,info);
figure(13); subplot(231); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/sector_mixed_p2_v2.msh');
figure(11); subplot(232); viewNodes(V,info,false);
figure(12); subplot(232); viewLineElements(V,LE,info);
figure(13); subplot(232); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV2('../meshes/sector_mixed_p3_v2.msh');
figure(11); subplot(233); viewNodes(V,info,false);
figure(12); subplot(233); viewLineElements(V,LE,info);
figure(13); subplot(233); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/sector_mixed_p2_v4.msh');
figure(11); subplot(234); viewNodes(V,info,false);
figure(12); subplot(234); viewLineElements(V,LE,info);
figure(13); subplot(234); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/sector_mixed_p2_v4.msh');
figure(11); subplot(235); viewNodes(V,info,false);
figure(12); subplot(235); viewLineElements(V,LE,info);
figure(13); subplot(235); viewSurfaceElements(V,SE,info);

[V,~,SE,LE,~,~,info] = GMSHparserV4('../meshes/sector_mixed_p3_v4.msh');
figure(11); subplot(236); viewNodes(V,info,false);
figure(12); subplot(236); viewLineElements(V,LE,info);
figure(13); subplot(236); viewSurfaceElements(V,SE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/sector_extruded_mixed_p1_v2.msh');
figure(14); subplot(231); viewNodes(V,info,false);
figure(15); subplot(231); viewSurfaceElements(V,SE,info);
figure(16); subplot(231); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/sector_extruded_mixed_p2_v2.msh');
figure(14); subplot(232); viewNodes(V,info,false);
figure(15); subplot(232); viewSurfaceElements(V,SE,info);
figure(16); subplot(232); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV2('../meshes/sector_extruded_mixed_p3_v2.msh');
figure(14); subplot(233); viewNodes(V,info,false);
figure(15); subplot(233); viewSurfaceElements(V,SE,info);
figure(16); subplot(233); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/sector_extruded_mixed_p1_v4.msh');
figure(14); subplot(234); viewNodes(V,info,false);
figure(15); subplot(234); viewSurfaceElements(V,SE,info);
figure(16); subplot(234); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/sector_extruded_mixed_p2_v4.msh');
figure(14); subplot(235); viewNodes(V,info,false);
figure(15); subplot(235); viewSurfaceElements(V,SE,info);
figure(16); subplot(235); viewVolumetricElements(V,VE,info);

[V,VE,SE,~,~,~,info] = GMSHparserV4('../meshes/sector_extruded_mixed_p3_v4.msh');
figure(14); subplot(236); viewNodes(V,info,false);
figure(15); subplot(236); viewSurfaceElements(V,SE,info);
figure(16); subplot(236); viewVolumetricElements(V,VE,info);

% Conclusion:
% * GMSH format 2.2 is easier to read and to use directly with
%   single-partitioned meshes. However, format 4.1 is more suitable for
%   handling partitioned domains as it provides the interfacial elements
%   required for comunications between partitions. 
% * After developing several FV and DG solvers, I come to the conclussion
%   that Gmsh is a fragile tool. Large meshes, specially with
%   periodic conditions are not always well formed. The best strategy is to
%   generate a single-partition mesh and use metis or scotch to partition
%   it within your solver.
% * Lastly, notice that Matlab functions `trimesh` and `tetramesh` were
%   never designed to handle high-order elements or curved meshes. So their 
%   visualization capabilities for high-order elements is limited.
%                                                          M.D. 2026.06.25
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot/Display mesh elements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function viewNodes(V,info,print_numbers)
    if nargin < 3
        print_numbers = true;
    end
    % Plot nodes with global IDs:
    x = V(:,1); y = V(:,2); z = V(:,3);
    hold on
    scatter3(x,y,z,'.r'); 
    if print_numbers
        for i=1:length(V)
            text(x(i),y(i),z(i),num2str(i));
        end
    end
    hold off
    % Print title and axis
    title(sprintf('%d-D GMSH v%g, mesh order %d',info.Dim,info.version,...
        info.element_order),'Interpreter','latex');
    xlabel('$x$','Interpreter','latex');
    ylabel('$y$','Interpreter','latex');
    if (info.Dim==2),view(2); else 
        zlabel('$z$','Interpreter','latex'); view(3);
    end
    % Use latex font for tick
    set(groot,'defaultAxesTickLabelInterpreter','latex');
end

function viewLineElements(V,E,info)
    % Plot surface elements with global IDs:
    x = V(:,1); y = V(:,2); z = V(:,3);
    lx=x(E.lin.EToV); ly=y(E.lin.EToV); lz=z(E.lin.EToV);
    xc=mean(lx,2); yc=mean(ly,2); zc=mean(lz,3);
    hold on
    for i=1:length(E.lin.EToV)
        plot3(lx(i,:),ly(i,:),lz(i,:),'-r'); 
        text(xc(i),yc(i),zc(i),num2str(i)); 
    end
    hold off
    % Print title and axis
    title(sprintf('%d-D GMSH v%g, mesh order %d',info.Dim,info.version,...
        info.element_order),'Interpreter','latex');
    xlabel('$x$','Interpreter','latex');
    ylabel('$y$','Interpreter','latex');
    if (info.Dim==2),view(2); else 
        zlabel('$z$','Interpreter','latex'); view(3);
    end
    % Use latex font for tick
    set(groot,'defaultAxesTickLabelInterpreter','latex');
end

function viewSurfaceElements(V,E,info)
    % Plot surface elements with global IDs:
    x = V(:,1); y = V(:,2); z = V(:,3);
    hold on
    trimesh(E.tri.EToV,x,y,z,'facecolor','none');
    trimesh(E.quad.EToV,x,y,z,'facecolor','none');
    hold off
    % Print title and axis
    title(sprintf('%d-D GMSH v%g, mesh order %d',info.Dim,info.version,...
        info.element_order),'Interpreter','latex');
    xlabel('$x$','Interpreter','latex');
    ylabel('$y$','Interpreter','latex');
    if (info.Dim==2),view(2); else 
        zlabel('$z$','Interpreter','latex'); view(3);
    end
    % Use latex font for tick
    set(groot,'defaultAxesTickLabelInterpreter','latex');
end

function viewVolumetricElements(V,E,info)
    % Plot surface elements with global IDs:
    x = V(:,1); y = V(:,2); z = V(:,3);
    hold on
    trimesh(E.tet.EToV,x,y,z,'facecolor','none');
    trimesh(E.hex.EToV,x,y,z,'facecolor','none');
    trimesh(E.prism.EToV,x,y,z,'facecolor','none');
    hold off
    % Print title and axis
    title(sprintf('%d-D GMSH v%g, mesh order %d',info.Dim,info.version,...
        info.element_order),'Interpreter','latex');
    xlabel('$x$','Interpreter','latex');
    ylabel('$y$','Interpreter','latex');
    if (info.Dim==2),view(2); else 
        zlabel('$z$','Interpreter','latex'); view(3);
    end
    % Use latex font for tick
    set(groot,'defaultAxesTickLabelInterpreter','latex');
end

function viewPartVolumes(V,E,tag,info)
    % Plot surface elements with global IDs:
    E_tet_Tags = E.tet.part_tag;
    E_hex_Tags = E.hex.part_tag;
    E_prism_Tags = E.prism.part_tag;
    partitioned_tet_EToV=E.tet.EToV(E_tet_Tags==tag,:);
    partitioned_hex_EToV=E.tet.EToV(E_hex_Tags==tag,:);
    partitioned_prism_EToV=E.tet.EToV(E_prism_Tags==tag,:);
    hold on
    tetramesh(partitioned_tet_EToV,V,'facecolor','w');
    tetramesh(partitioned_hex_EToV,V,'facecolor','w');
    tetramesh(partitioned_prism_EToV,V,'facecolor','w');
    hold off
    % Print title and axis
    title(sprintf('%d-D GMSH v%g, partition %d',info.Dim,info.version,tag),...
        'Interpreter','latex');
    xlabel('$x$','Interpreter','latex');
    ylabel('$y$','Interpreter','latex');
    if (info.Dim==2),view(2); else 
        zlabel('$z$','Interpreter','latex'); view(3);
    end
    % Use latex font for tick
    set(groot,'defaultAxesTickLabelInterpreter','latex');
end