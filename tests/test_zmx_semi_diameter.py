import os
import pytest
import optiland.backend as be
from optiland.fileio.zemax_handler import load_zemax_file

def test_zmx_semi_diameter_preservation():
    """
    Test that semi-diameters (DIAM operands) from a ZMX file are correctly
    imported and preserved even after a paraxial update.
    """
    # Use a file known to have DIAM operands
    current_dir = os.path.dirname(__file__)
    zmx_file = os.path.join(current_dir, 'zemax_files', 'thorlabs_lj1598l1.zmx')
    
    if not os.path.exists(zmx_file):
        pytest.skip(f"ZMX file not found: {zmx_file}")
    
    # Load the optic
    optic = load_zemax_file(zmx_file)
    
    # Check that semi-apertures are marked as fixed
    # In lj1598l1, surface 1 is a cylindrical lens with defined diameter
    s1 = optic.surface_group.surfaces[1]
    assert getattr(s1, 'is_semi_aperture_fixed', False) is True
    original_semi_aperture = s1.semi_aperture
    assert original_semi_aperture > 0
    
    # Run paraxial update (which usually overwrites semi-apertures)
    optic.update_paraxial()
    
    # Verify that the semi-aperture was preserved
    assert s1.semi_aperture == original_semi_aperture
    assert getattr(s1, 'is_semi_aperture_fixed', False) is True

def test_manual_semi_diameter_setting():
    """
    Test that manually setting a semi-aperture also marks it as fixed.
    """
    from optiland.optic.optic import Optic
    
    optic = Optic()
    optic.add_surface(index=0, surface_type='standard', thickness=be.inf)
    optic.add_surface(index=1, surface_type='standard', thickness=10, semi_aperture=5.0)
    optic.add_surface(index=2, surface_type='standard')
    
    s1 = optic.surface_group.surfaces[1]
    assert s1.semi_aperture == 5.0
    assert getattr(s1, 'is_semi_aperture_fixed', False) is True
    
    # Surface 2 should NOT be fixed
    s2 = optic.surface_group.surfaces[2]
    assert getattr(s2, 'is_semi_aperture_fixed', False) is False
