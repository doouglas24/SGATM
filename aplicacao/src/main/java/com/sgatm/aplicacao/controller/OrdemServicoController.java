package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.OrdemServico;
import com.sgatm_db.aplicacao.repository.ClienteRepository;
import com.sgatm_db.aplicacao.repository.EquipamentoRepository;
import com.sgatm_db.aplicacao.repository.OrdemServicoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import jakarta.servlet.http.HttpSession;

@Controller
public class OrdemServicoController {

    @Autowired
    private OrdemServicoRepository ordemServicoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private EquipamentoRepository equipamentoRepository;

    @GetMapping("/ordens")
    public String listarOrdens(HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) return "redirect:/login";

        model.addAttribute("ordens", ordemServicoRepository.findAll());
        model.addAttribute("ordemServico", new OrdemServico());
        model.addAttribute("clientes", clienteRepository.findAll());
        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        return "ordens";
    }

    @PostMapping("/ordens")
    public String salvarOrdem(@ModelAttribute OrdemServico ordemServico, HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) return "redirect:/login";

        // Validação de segurança por perfil para o status
        if (cargo.equals("Atendente") && !ordemServico.getStatus().equals("Aberta") && !ordemServico.getStatus().equals("Cancelada")) {
            return "redirect:/ordens?erro=Acesso Negado para este status!";
        }
        if (cargo.equals("Tecnico") && !ordemServico.getStatus().equals("Em Andamento") && !ordemServico.getStatus().equals("Concluída") && !ordemServico.getStatus().equals("Cancelada")) {
            return "redirect:/ordens?erro=Acesso Negado para este status!";
        }
        if (cargo.equals("OutroSetor") && !ordemServico.getStatus().equals("Entregue") && !ordemServico.getStatus().equals("Cancelada")) {
            return "redirect:/ordens?erro=Acesso Negado para este status!";
        }

        ordemServicoRepository.save(ordemServico);
        return "redirect:/ordens";
    }

    @GetMapping("/ordens/editar/{id}")
    public String carregarEdicaoOrdem(@PathVariable Long id, HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) return "redirect:/login";
        
        OrdemServico os = ordemServicoRepository.findById(id).orElse(null);
        model.addAttribute("ordemServico", os);
        model.addAttribute("ordens", ordemServicoRepository.findAll());
        model.addAttribute("clientes", clienteRepository.findAll());
        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        return "ordens";
    }

    @GetMapping("/ordens/deletar/{id}")
    public String deletarOrdem(@PathVariable Long id, HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null || !cargo.equals("Gerente")) {
            return "redirect:/ordens?erro=Apenas o Gerente pode apagar ordens de serviço!";
        }
        ordemServicoRepository.deleteById(id);
        return "redirect:/ordens";
    }
}